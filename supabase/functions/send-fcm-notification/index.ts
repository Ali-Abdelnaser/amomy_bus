import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ============================================================================
// FCM HTTP v1 Client Types & Logic (Self-Contained)
// ============================================================================

export interface FirebaseConfig {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

export interface FcmNotificationPayload {
  title?: string;
  body?: string;
  imageUrl?: string;
}

export interface FcmMessage {
  token: string;
  notification?: FcmNotificationPayload;
  data?: Record<string, string>;
  android?: {
    priority?: "normal" | "high";
    notification?: {
      channelId?: string;
      sound?: string;
      clickAction?: string;
    };
  };
  apns?: {
    payload?: {
      aps?: {
        sound?: string;
        badge?: number;
        contentAvailable?: boolean;
      };
    };
  };
}

export interface FcmSendResult {
  success: boolean;
  messageId?: string;
  error?: string;
  unregisteredToken?: boolean;
}

let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

export function getFirebaseConfig(): FirebaseConfig | null {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID")?.trim();
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")?.trim();
  const rawPrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.trim();

  if (!projectId || !clientEmail || !rawPrivateKey) {
    return null;
  }

  let normalizedKey = rawPrivateKey;
  if (normalizedKey.startsWith('"') && normalizedKey.endsWith('"')) {
    normalizedKey = normalizedKey.substring(1, normalizedKey.length - 1);
  }
  normalizedKey = normalizedKey.replace(/\\n/g, "\n");

  return {
    projectId,
    clientEmail,
    privateKey: normalizedKey,
  };
}

export function isFirebaseConfigured(): boolean {
  return getFirebaseConfig() !== null;
}

function base64UrlEncode(data: Uint8Array | string): string {
  let binaryStr: string;
  if (typeof data === "string") {
    binaryStr = btoa(unescape(encodeURIComponent(data)));
  } else {
    let binary = "";
    const len = data.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(data[i]);
    }
    binaryStr = btoa(binary);
  }
  return binaryStr
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  
  let keyBody = pem;
  const headerIdx = keyBody.indexOf(pemHeader);
  if (headerIdx !== -1) {
    keyBody = keyBody.substring(headerIdx + pemHeader.length);
  }
  const footerIdx = keyBody.indexOf(pemFooter);
  if (footerIdx !== -1) {
    keyBody = keyBody.substring(0, footerIdx);
  }
  
  keyBody = keyBody.replace(/\s+/g, "");
  const binaryDerString = atob(keyBody);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

export async function getGoogleAccessToken(config: FirebaseConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  if (cachedAccessToken && tokenExpiresAt > now + 300) {
    return cachedAccessToken;
  }

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const payload = {
    iss: config.clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;

  const privateKey = await importPrivateKey(config.privateKey);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signatureInput),
  );

  const encodedSignature = base64UrlEncode(new Uint8Array(signature));
  const jwtAssertion = `${signatureInput}.${encodedSignature}`;

  const tokenResp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwtAssertion,
    }),
  });

  if (!tokenResp.ok) {
    const errText = await tokenResp.text();
    throw new Error(`Google OAuth2 Token Exchange Failed: ${tokenResp.status} ${errText}`);
  }

  const tokenData = await tokenResp.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);

  return cachedAccessToken!;
}

export async function sendFcmMessage(
  message: FcmMessage,
  config: FirebaseConfig,
): Promise<FcmSendResult> {
  try {
    const accessToken = await getGoogleAccessToken(config);
    const url = `https://fcm.googleapis.com/v1/projects/${config.projectId}/messages:send`;

    const fcmPayload = {
      message: {
        token: message.token,
        ...(message.notification ? { notification: message.notification } : {}),
        ...(message.data ? { data: message.data } : {}),
        android: {
          priority: message.android?.priority ?? "high",
          notification: {
            channel_id: message.android?.notification?.channelId ?? "amomy_high_importance",
            sound: message.android?.notification?.sound ?? "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: message.apns?.payload?.aps?.sound ?? "default",
              badge: message.apns?.payload?.aps?.badge ?? 1,
              content_available: message.apns?.payload?.aps?.contentAvailable ?? true,
            },
          },
        },
      },
    };

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json; UTF-8",
      },
      body: JSON.stringify(fcmPayload),
    });

    if (response.ok) {
      const data = await response.json();
      return {
        success: true,
        messageId: data.name,
      };
    }

    const errorData = await response.json().catch(() => ({}));
    const errorCode = errorData?.error?.details?.[0]?.errorCode || errorData?.error?.status || "";
    const isUnregistered =
      errorCode === "UNREGISTERED" ||
      errorCode === "NOT_FOUND" ||
      response.status === 404 ||
      JSON.stringify(errorData).includes("UNREGISTERED") ||
      JSON.stringify(errorData).includes("Requested entity was not found");

    return {
      success: false,
      error: errorData?.error?.message || `FCM error HTTP ${response.status}`,
      unregisteredToken: isUnregistered,
    };
  } catch (err: unknown) {
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

// ============================================================================
// CENTRAL AUTHORITATIVE EVENT CATALOG (TypeScript Definition)
// ============================================================================

export interface EventCatalogItem {
  type: string;
  category: "service_updates" | "booking_updates" | "wallet_updates" | "trip_updates";
  titleAr: string;
  bodyAr: string;
  titleEn: string;
  bodyEn: string;
  screen: string;
  data: Record<string, string>;
  isPushOptional: boolean;
  dedupeStrategy: string;
}

export const EVENT_CATALOG: Record<string, EventCatalogItem> = {
  system: {
    type: "system",
    category: "service_updates",
    titleAr: "إشعار من عمومي",
    bodyAr: "تحديثات وتنبيهات هامة تخص خدمة عمومي باص.",
    titleEn: "AMOMY Notice",
    bodyEn: "Important updates regarding AMOMY bus service.",
    screen: "notifications",
    data: { screen: "notifications" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  general_announcement: {
    type: "general_announcement",
    category: "service_updates",
    titleAr: "إعلان عام",
    bodyAr: "يسر عمومي إعلامكم بجداول ومواعيد التشغيل المحدثة.",
    titleEn: "General Announcement",
    bodyEn: "AMOMY is pleased to announce updated service schedules.",
    screen: "home",
    data: { screen: "home" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  service_update: {
    type: "service_update",
    category: "service_updates",
    titleAr: "تحديث الخدمة",
    bodyAr: "تم تحديث مسارات ومحطات التوقف لخدمة أفضل.",
    titleEn: "Service Update",
    bodyEn: "Routes and stops have been updated for better service.",
    screen: "notifications",
    data: { screen: "notifications" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  booking_confirmed: {
    type: "booking_confirmed",
    category: "booking_updates",
    titleAr: "تم تأكيد حجزك",
    bodyAr: "تم تأكيد رحلتك الساعة 08:00 صباحاً والمقعد رقم 7.",
    titleEn: "Booking confirmed",
    bodyEn: "Your 08:00 AM trip is confirmed. Seat #7.",
    screen: "ticket",
    data: { screen: "ticket", booking_id: "test-booking-id" },
    isPushOptional: true,
    dedupeStrategy: "booking_id",
  },
  booking_cancelled: {
    type: "booking_cancelled",
    category: "booking_updates",
    titleAr: "تم إلغاء الحجز",
    bodyAr: "تم إلغاء حجز رحلتك بنجاح واسترداد النقاط إلى محفظتك.",
    titleEn: "Booking cancelled",
    bodyEn: "Your trip booking has been cancelled and points returned.",
    screen: "trips",
    data: { screen: "trips" },
    isPushOptional: true,
    dedupeStrategy: "booking_id",
  },
  seat_changed: {
    type: "seat_changed",
    category: "booking_updates",
    titleAr: "تم تغيير المقعد",
    bodyAr: "تم تغيير مقعدك إلى رقم 14 بنجاح.",
    titleEn: "Seat updated",
    bodyEn: "Your seat has been changed to #14.",
    screen: "ticket",
    data: { screen: "ticket", booking_id: "test-booking-id" },
    isPushOptional: true,
    dedupeStrategy: "booking_id",
  },
  topup_approved: {
    type: "topup_approved",
    category: "wallet_updates",
    titleAr: "تم قبول طلب الشحن",
    bodyAr: "تم إضافة 300 نقطة إلى محفظتك بنجاح.",
    titleEn: "Top-up approved",
    bodyEn: "300 points were added to your wallet.",
    screen: "wallet",
    data: { screen: "wallet" },
    isPushOptional: true,
    dedupeStrategy: "request_id",
  },
  topup_rejected: {
    type: "topup_rejected",
    category: "wallet_updates",
    titleAr: "لم يتم قبول طلب الشحن",
    bodyAr: "راجع تفاصيل الطلب أو أعد المحاولة بإرفاق إيصال صالح.",
    titleEn: "Top-up not approved",
    bodyEn: "Please review your top-up request or submit a valid receipt.",
    screen: "wallet",
    data: { screen: "wallet" },
    isPushOptional: true,
    dedupeStrategy: "request_id",
  },
  wallet_credit: {
    type: "wallet_credit",
    category: "wallet_updates",
    titleAr: "إضافة نقاط",
    bodyAr: "تم إضافة 50 نقطة مكافأة إلى رصيدك.",
    titleEn: "Points credited",
    bodyEn: "50 reward points were added to your balance.",
    screen: "wallet",
    data: { screen: "wallet" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  wallet_refund: {
    type: "wallet_refund",
    category: "wallet_updates",
    titleAr: "تم استرداد النقاط",
    bodyAr: "تمت إعادة 100 نقطة إلى محفظتك.",
    titleEn: "Points refunded",
    bodyEn: "100 points were returned to your wallet.",
    screen: "wallet",
    data: { screen: "wallet" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  bus_approaching: {
    type: "bus_approaching",
    category: "trip_updates",
    titleAr: "الأتوبيس يقترب من محطتك",
    bodyAr: "عمومي باص يقترب من محطة أحمد ماهر. استعد للركوب.",
    titleEn: "Your bus is approaching",
    bodyEn: "Your bus is approaching Ahmed Maher stop. Please get ready.",
    screen: "live_map",
    data: { screen: "live_map", stop_name: "Ahmed Maher" },
    isPushOptional: true,
    dedupeStrategy: "booking_run_approaching",
  },
  bus_arrived_at_boarding_stop: {
    type: "bus_arrived_at_boarding_stop",
    category: "trip_updates",
    titleAr: "الأتوبيس وصل محطتك",
    bodyAr: "الأتوبيس وصل الآن إلى محطة أحمد ماهر.",
    titleEn: "Your bus has arrived",
    bodyEn: "The bus has arrived at Ahmed Maher stop.",
    screen: "live_map",
    data: { screen: "live_map", stop_name: "Ahmed Maher" },
    isPushOptional: true,
    dedupeStrategy: "booking_run_arrival",
  },
  trip_update: {
    type: "trip_update",
    category: "trip_updates",
    titleAr: "تحديث على الرحلة",
    bodyAr: "الأوتوبيس يسير بانتظام في مسار الرحلة الحالي.",
    titleEn: "Trip update",
    bodyEn: "The bus is proceeding normally on its current route.",
    screen: "live_map",
    data: { screen: "live_map" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  trip_delayed: {
    type: "trip_delayed",
    category: "trip_updates",
    titleAr: "تحديث على الرحلة",
    bodyAr: "يوجد تأخير بسيط بسبب حركة المرور على مسار الرحلة.",
    titleEn: "Trip update",
    bodyEn: "Your current trip is slightly delayed due to traffic.",
    screen: "live_map",
    data: { screen: "live_map" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
  next_stop_update: {
    type: "next_stop_update",
    category: "trip_updates",
    titleAr: "المحطة القادمة",
    bodyAr: "المحطة القادمة هي جيهان.",
    titleEn: "Next stop",
    bodyEn: "The next stop is Jihan.",
    screen: "live_map",
    data: { screen: "live_map", next_stop: "Jihan" },
    isPushOptional: true,
    dedupeStrategy: "none",
  },
};

// ============================================================================
// HTTP Server / Edge Handler
// ============================================================================

Deno.serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-internal-secret",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const config = getFirebaseConfig();
    if (!config) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Firebase service account credentials are not configured on Supabase.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (req.method === "GET") {
      return new Response(
        JSON.stringify({
          status: "ok",
          configured: true,
          projectId: config.projectId,
          clientEmail: config.clientEmail,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const payload = await req.json().catch(() => ({}));

    // Health action via POST
    if (payload.action === "health" || payload.action === "check_config") {
      return new Response(
        JSON.stringify({
          status: "ok",
          configured: true,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");

    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // =========================================================================
    // 1. NOTIFICATION TEST LAB (Tester Account Functional Simulator)
    // =========================================================================
    if (payload.action === "test_event" || payload.action === "self_test") {
      if (!token) {
        return new Response(
          JSON.stringify({ success: false, error: "Unauthorized: Missing authentication token" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Verify the authenticated caller
      const { data: { user }, error: userError } = await adminClient.auth.getUser(token);
      if (userError || !user) {
        return new Response(
          JSON.stringify({ success: false, error: "Unauthorized: Invalid user session" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Check tester authorization
      const { data: testerData } = await adminClient
        .from("app_testers")
        .select("notification_lab_enabled")
        .eq("user_id", user.id)
        .maybeSingle();

      const { data: roleData } = await adminClient
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .maybeSingle();

      const { data: qaOverrideData } = await adminClient
        .from("qa_booking_time_overrides")
        .select("enabled")
        .eq("user_id", user.id)
        .maybeSingle();

      const isTester =
        Boolean(testerData?.notification_lab_enabled) ||
        roleData?.role === "admin" ||
        roleData?.role === "super_admin" ||
        Boolean(qaOverrideData?.enabled);

      if (!isTester && payload.action === "test_event") {
        return new Response(
          JSON.stringify({ success: false, error: "Notification Test Lab access denied." }),
          {
            status: 403,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Resolve and validate event catalog entry
      const eventKey = String(payload.event_type || payload.type || (payload.action === "self_test" ? "system" : ""));
      if (payload.action === "test_event" && (!eventKey || !EVENT_CATALOG[eventKey])) {
        return new Response(
          JSON.stringify({ success: false, error: `Invalid or unsupported event_type: ${eventKey}` }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const catalogItem = EVENT_CATALOG[eventKey] || EVENT_CATALOG.system;

      const titleAr = payload.title_ar || catalogItem.titleAr;
      const bodyAr = payload.body_ar || catalogItem.bodyAr;
      const titleEn = payload.title_en || catalogItem.titleEn;
      const bodyEn = payload.body_en || catalogItem.bodyEn;
      const eventCategory = catalogItem.category;

      // 1. Always record in-app notification inbox row for the user
      let inboxInserted = false;
      try {
        const insertRes = await adminClient.from("notifications").insert({
          user_id: user.id,
          type: catalogItem.type,
          title_ar: titleAr,
          body_ar: bodyAr,
          title_en: titleEn,
          body_en: bodyEn,
          data: { ...catalogItem.data, ...(payload.data || {}) },
          created_at: new Date().toISOString(),
        });
        inboxInserted = !insertRes.error;
      } catch (_) {
        inboxInserted = false;
      }

      // 2. Evaluate recipient notification preferences
      const { data: prefs } = await adminClient
        .from("notification_preferences")
        .select("all_enabled, service_updates, booking_updates, wallet_updates, trip_updates")
        .eq("user_id", user.id)
        .maybeSingle();

      const forceDelivery = Boolean(payload.force_delivery) && isTester;
      let isPushAllowed = true;

      if (!forceDelivery) {
        if (prefs) {
          if (!prefs.all_enabled) {
            isPushAllowed = false;
          } else {
            const categoryAllowed = prefs[eventCategory];
            if (categoryAllowed === false) {
              isPushAllowed = false;
            }
          }
        }
      }

      // 3. If push is suppressed by user preference
      if (!isPushAllowed) {
        return new Response(
          JSON.stringify({
            success: true,
            event_type: catalogItem.type,
            category: eventCategory,
            preference_suppressed: true,
            forced: false,
            notification_inbox_inserted: inboxInserted,
            delivered: 0,
            message: "In-app notification saved. Push delivery suppressed by your Notification Settings preference.",
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // 4. Push allowed: Fetch active device tokens for the caller
      const { data: deviceTokens } = await adminClient
        .from("user_device_tokens")
        .select("token, platform")
        .eq("user_id", user.id)
        .eq("is_active", true);

      if (!deviceTokens || deviceTokens.length === 0) {
        return new Response(
          JSON.stringify({
            success: true,
            event_type: catalogItem.type,
            category: eventCategory,
            preference_suppressed: false,
            forced: forceDelivery,
            notification_inbox_inserted: inboxInserted,
            total_devices: 0,
            delivered: 0,
            message: "In-app notification saved. No registered active device tokens found for push.",
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Optional delay
      if (typeof payload.delay_seconds === "number" && payload.delay_seconds > 0) {
        const safeDelay = Math.min(payload.delay_seconds, 30);
        await new Promise((resolve) => setTimeout(resolve, safeDelay * 1000));
      }

      // 5. Send FCM push to device tokens
      let deliveredCount = 0;
      let lastFcmError: string | undefined;

      for (const dt of deviceTokens) {
        const message: FcmMessage = {
          token: dt.token,
          notification: {
            title: titleEn,
            body: bodyEn,
          },
          data: {
            type: catalogItem.type,
            category: eventCategory,
            screen: catalogItem.screen,
            title_ar: titleAr,
            body_ar: bodyAr,
            title_en: titleEn,
            body_en: bodyEn,
            ...catalogItem.data,
            ...(payload.data || {}),
          },
          android: {
            priority: "high",
            notification: {
              channelId: "amomy_high_importance",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        const res = await sendFcmMessage(message, config);
        if (res.success) {
          deliveredCount++;
        } else {
          lastFcmError = res.error || "FCM dispatch error";
          if (res.unregisteredToken) {
            // Deactivate dead token
            await adminClient
              .from("user_device_tokens")
              .update({ is_active: false, updated_at: new Date().toISOString() })
              .eq("token", dt.token);
          }
        }
      }

      const allSuccess = deliveredCount > 0;
      return new Response(
        JSON.stringify({
          success: allSuccess,
          event_type: catalogItem.type,
          category: eventCategory,
          preference_suppressed: false,
          forced: forceDelivery,
          total_devices: deviceTokens.length,
          delivered: deliveredCount,
          fcm_failures: deviceTokens.length - deliveredCount,
          notification_inbox_inserted: inboxInserted,
          message: allSuccess ? "Test notification delivered successfully" : "Failed to deliver to device tokens",
          error: allSuccess ? undefined : lastFcmError,
        }),
        {
          status: allSuccess ? 200 : 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // =========================================================================
    // 2. GENERIC BACKEND AUTHORIZED SEND
    // =========================================================================
    const isServiceRole = token && (token === supabaseServiceKey || token.includes("service_role"));
    const internalSecret = req.headers.get("x-internal-secret");
    const validInternalSecret = Deno.env.get("INTERNAL_FCM_SECRET");
    const isInternalAuthorized =
      isServiceRole ||
      (validInternalSecret && internalSecret && internalSecret === validInternalSecret);

    if (!isInternalAuthorized) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Forbidden: Generic notification dispatch requires backend authorization.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // If dispatching by recipient_user_id
    const recipientUserId = payload.recipient_user_id || payload.user_id;
    const tokens: string[] = [];

    if (recipientUserId) {
      // 1. Check recipient preferences before push
      const eventType = payload.event_type || payload.type || "system";
      const catalogItem = EVENT_CATALOG[eventType] || EVENT_CATALOG.system;
      const category = catalogItem.category;

      const { data: recipientPrefs } = await adminClient
        .from("notification_preferences")
        .select("all_enabled, service_updates, booking_updates, wallet_updates, trip_updates")
        .eq("user_id", recipientUserId)
        .maybeSingle();

      if (recipientPrefs) {
        if (!recipientPrefs.all_enabled || recipientPrefs[category] === false) {
          return new Response(
            JSON.stringify({
              success: true,
              preference_suppressed: true,
              message: "Push suppressed by recipient preferences",
            }),
            {
              status: 200,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
          );
        }
      }

      // 2. Fetch active tokens
      const { data: userTokens } = await adminClient
        .from("user_device_tokens")
        .select("token")
        .eq("user_id", recipientUserId)
        .eq("is_active", true);

      if (userTokens) {
        for (const ut of userTokens) {
          if (ut.token) tokens.push(ut.token);
        }
      }
    } else if (typeof payload.token === "string" && payload.token.trim()) {
      tokens.push(payload.token.trim());
    } else if (Array.isArray(payload.tokens)) {
      for (const t of payload.tokens) {
        if (typeof t === "string" && t.trim()) {
          tokens.push(t.trim());
        }
      }
    }

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing active device tokens for recipient" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const title: string | undefined = payload.title || payload.notification?.title;
    const body: string | undefined = payload.body || payload.notification?.body;
    const data: Record<string, string> | undefined = payload.data;
    const channelId: string | undefined = payload.channelId || payload.channel_id;

    const results = [];
    for (const tokenItem of tokens) {
      const message: FcmMessage = {
        token: tokenItem,
        ...(title || body ? { notification: { title, body } } : {}),
        ...(data ? { data } : {}),
        android: {
          priority: "high",
          notification: {
            channelId: channelId || "amomy_high_importance",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const res = await sendFcmMessage(message, config);
      if (!res.success && res.unregisteredToken) {
        // Deactivate permanently invalid token
        await adminClient
          .from("user_device_tokens")
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .eq("token", tokenItem);
      }

      results.push({
        token_suffix: tokenItem.length > 8 ? `...${tokenItem.slice(-6)}` : tokenItem,
        success: res.success,
        messageId: res.messageId,
        error: res.error,
        unregisteredToken: res.unregisteredToken,
      });
    }

    const allSuccessful = results.every((r) => r.success);
    const someSuccessful = results.some((r) => r.success);

    return new Response(
      JSON.stringify({
        success: allSuccessful,
        partial: someSuccessful && !allSuccessful,
        total: results.length,
        delivered: results.filter((r) => r.success).length,
        results,
      }),
      {
        status: allSuccessful ? 200 : (someSuccessful ? 207 : 502),
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (_e) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "Internal notification dispatch error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
