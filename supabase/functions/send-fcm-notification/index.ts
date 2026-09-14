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
  const assertion = `${signatureInput}.${encodedSignature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error("Failed to exchange OAuth2 JWT for Google access token");
  }

  const tokenData = await tokenResponse.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);

  return cachedAccessToken!;
}

export async function sendFcmMessage(
  message: FcmMessage,
  config?: FirebaseConfig | null,
): Promise<FcmSendResult> {
  const activeConfig = config ?? getFirebaseConfig();
  if (!activeConfig) {
    return {
      success: false,
      error: "Firebase credentials not configured",
    };
  }

  try {
    const accessToken = await getGoogleAccessToken(activeConfig);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${activeConfig.projectId}/messages:send`;

    const fcmMessageBody: Record<string, unknown> = {
      token: message.token,
    };

    if (message.notification) {
      fcmMessageBody.notification = {
        title: message.notification.title,
        body: message.notification.body,
        ...(message.notification.imageUrl ? { image: message.notification.imageUrl } : {}),
      };
    }

    if (message.data) {
      fcmMessageBody.data = message.data;
    }

    if (message.android) {
      fcmMessageBody.android = {
        priority: message.android.priority || "high",
        notification: {
          channel_id: message.android.notification?.channelId || "amomy_bus_tracking_channel",
          sound: message.android.notification?.sound || "default",
          ...(message.android.notification?.clickAction
            ? { click_action: message.android.notification.clickAction }
            : {}),
        },
      };
    }

    if (message.apns) {
      fcmMessageBody.apns = message.apns;
    }

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: fcmMessageBody }),
    });

    if (response.ok) {
      const data = await response.json();
      return {
        success: true,
        messageId: data.name,
      };
    }

    const errorJson = await response.json().catch(() => ({}));
    const errorCode = errorJson?.error?.details?.[0]?.errorCode || errorJson?.error?.status || "UNKNOWN";
    const isUnregistered =
      errorCode === "UNREGISTERED" ||
      errorJson?.error?.message?.includes("not registered") ||
      response.status === 404;

    return {
      success: false,
      error: `FCM error status: ${response.status}`,
      unregisteredToken: isUnregistered,
    };
  } catch (_e) {
    return {
      success: false,
      error: "Failed to dispatch FCM message",
    };
  }
}

// ============================================================================
// Edge Function Request Handler
// ============================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-internal-secret",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);

  // Health / Config Validation Route (Safe: never exposes secrets or tokens)
  if (req.method === "GET" || url.pathname.endsWith("/health")) {
    const configured = isFirebaseConfigured();
    return new Response(
      JSON.stringify({
        status: "ok",
        configured,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const config = getFirebaseConfig();
    if (!config) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Firebase service credentials are not configured on the server.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const payload = await req.json().catch(() => null);
    if (!payload) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid JSON body" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

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
    // 1. SAFE DEVELOPER SELF-TEST PUSH PATH
    // =========================================================================
    if (payload.action === "self_test") {
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

      // Fetch active device tokens for THIS authenticated user only
      const { data: deviceTokens, error: tokensError } = await adminClient
        .from("user_device_tokens")
        .select("token, platform")
        .eq("user_id", user.id)
        .eq("is_active", true);

      if (tokensError || !deviceTokens || deviceTokens.length === 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "No active device tokens found for your account. Please enable notifications in the app first.",
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const titleAr = "اختبار إشعارات عمومي";
      const bodyAr = "الإشعارات تعمل بنجاح.";
      const titleEn = "AMOMY Notification Test";
      const bodyEn = "Push notifications are working successfully.";

      // Insert matching in-app notification record
      await adminClient.from("notifications").insert({
        user_id: user.id,
        type: "system",
        title_ar: titleAr,
        body_ar: bodyAr,
        title_en: titleEn,
        body_en: bodyEn,
        data: { screen: "notifications" },
      });

      // Send push to active device tokens
      let deliveredCount = 0;
      for (const dt of deviceTokens) {
        const message: FcmMessage = {
          token: dt.token,
          notification: {
            title: titleEn,
            body: bodyEn,
          },
          data: {
            screen: "notifications",
            type: "system",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "amomy_bus_tracking_channel",
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
        if (res.success) {
          deliveredCount++;
        } else if (res.unregisteredToken) {
          // Deactivate permanently invalid token
          await adminClient
            .from("user_device_tokens")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("token", dt.token);
        }
      }

      return new Response(
        JSON.stringify({
          success: deliveredCount > 0,
          total_devices: deviceTokens.length,
          delivered: deliveredCount,
          message: deliveredCount > 0 ? "Test notification delivered" : "Failed to deliver to device tokens",
        }),
        {
          status: deliveredCount > 0 ? 200 : 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // =========================================================================
    // 2. GENERIC BACKEND AUTHORIZED SEND
    // =========================================================================
    // Verify caller is service_role or internal admin secret
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

    const tokens: string[] = [];
    if (typeof payload.token === "string" && payload.token.trim()) {
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
        JSON.stringify({ success: false, error: "Missing required 'token' or 'tokens' field" }),
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
            channelId: channelId || "amomy_bus_tracking_channel",
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
