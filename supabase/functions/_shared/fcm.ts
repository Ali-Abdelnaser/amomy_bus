// Firebase Cloud Messaging (FCM) HTTP v1 Client for Supabase Edge Functions
// Uses RS256 JWT assertion with Google OAuth2 to authenticate service accounts.

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

/**
 * Validates and retrieves Firebase Service Account configuration from environment variables.
 * Returns null if any secret is missing or empty.
 */
export function getFirebaseConfig(): FirebaseConfig | null {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID")?.trim();
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")?.trim();
  const rawPrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.trim();

  if (!projectId || !clientEmail || !rawPrivateKey) {
    return null;
  }

  // Normalize escaped private key newlines safely (replaces literal "\n" with real newlines)
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

/**
 * Health check helper reporting configuration status without exposing credentials.
 */
export function isFirebaseConfigured(): boolean {
  return getFirebaseConfig() !== null;
}

/**
 * Base64URL encoder utility.
 */
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

/**
 * Imports PKCS#8 PEM private key into CryptoKey for Web Crypto RS256 signing.
 */
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

/**
 * Generates an OAuth2 access token with Google Firebase Messaging scope.
 */
export async function getGoogleAccessToken(config: FirebaseConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Return cached token if valid for at least 5 more minutes
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

/**
 * Sends a single FCM message via FCM HTTP v1.
 */
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
