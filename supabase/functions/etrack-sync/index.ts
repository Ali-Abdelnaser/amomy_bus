import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Pure MD5 implementation (zero dependencies, fully portable across edge runtimes)
function md5(string: string): string {
  function rotateLeft(lValue: number, iShiftBits: number) {
    return (lValue << iShiftBits) | (lValue >>> (32 - iShiftBits));
  }
  function addUnsigned(lX: number, lY: number) {
    const lX8 = lX & 0x80000000;
    const lY8 = lY & 0x80000000;
    const lX4 = lX & 0x40000000;
    const lY4 = lY & 0x40000000;
    const lResult = (lX & 0x3fffffff) + (lY & 0x3fffffff);
    if (lX4 & lY4) return lResult ^ 0x80000000 ^ lX8 ^ lY8;
    if (lX4 | lY4) {
      if (lResult & 0x40000000) return lResult ^ 0xc0000000 ^ lX8 ^ lY8;
      return lResult ^ 0x40000000 ^ lX8 ^ lY8;
    }
    return lResult ^ lX8 ^ lY8;
  }
  function F(x: number, y: number, z: number) { return (x & y) | (~x & z); }
  function G(x: number, y: number, z: number) { return (x & z) | (y & ~z); }
  function H(x: number, y: number, z: number) { return x ^ y ^ z; }
  function I(x: number, y: number, z: number) { return y ^ (x | ~z); }
  function FF(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    return addUnsigned(rotateLeft(addUnsigned(a, addUnsigned(addUnsigned(F(b, c, d), x), ac)), s), b);
  }
  function GG(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    return addUnsigned(rotateLeft(addUnsigned(a, addUnsigned(addUnsigned(G(b, c, d), x), ac)), s), b);
  }
  function HH(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    return addUnsigned(rotateLeft(addUnsigned(a, addUnsigned(addUnsigned(H(b, c, d), x), ac)), s), b);
  }
  function II(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    return addUnsigned(rotateLeft(addUnsigned(a, addUnsigned(addUnsigned(I(b, c, d), x), ac)), s), b);
  }
  function convertToWordArray(string: string) {
    let lWordCount;
    const lMessageLength = string.length;
    const lNumberOfWords_temp1 = lMessageLength + 8;
    const lNumberOfWords_temp2 = (lNumberOfWords_temp1 - (lNumberOfWords_temp1 % 64)) / 64;
    const lNumberOfWords = (lNumberOfWords_temp2 + 1) * 16;
    const lWordArray = Array(lNumberOfWords - 1);
    let lBytePosition = 0;
    let lByteCount = 0;
    while (lByteCount < lMessageLength) {
      lWordCount = (lByteCount - (lByteCount % 4)) / 4;
      lBytePosition = (lByteCount % 4) * 8;
      lWordArray[lWordCount] = (lWordArray[lWordCount] | (string.charCodeAt(lByteCount) << lBytePosition));
      lByteCount++;
    }
    lWordCount = (lByteCount - (lByteCount % 4)) / 4;
    lBytePosition = (lByteCount % 4) * 8;
    lWordArray[lWordCount] = lWordArray[lWordCount] | (0x80 << lBytePosition);
    lWordArray[lNumberOfWords - 2] = lMessageLength << 3;
    lWordArray[lNumberOfWords - 1] = lMessageLength >>> 29;
    return lWordArray;
  }
  function wordToHex(lValue: number) {
    let WordToHexValue = "", WordToHexValue_temp = "", lByte, lCount;
    for (lCount = 0; lCount <= 3; lCount++) {
      lByte = (lValue >>> (lCount * 8)) & 255;
      WordToHexValue_temp = "0" + lByte.toString(16);
      WordToHexValue = WordToHexValue + WordToHexValue_temp.substr(WordToHexValue_temp.length - 2, 2);
    }
    return WordToHexValue;
  }
  const x = convertToWordArray(string);
  let a = 0x67452301, b = 0xefcdab89, c = 0x98badcfe, d = 0x10325476;
  const S11 = 7, S12 = 12, S13 = 17, S14 = 22;
  const S21 = 5, S22 = 9, S23 = 14, S24 = 20;
  const S31 = 4, S32 = 11, S33 = 16, S34 = 23;
  const S41 = 6, S42 = 10, S43 = 15, S44 = 21;
  for (let k = 0; k < x.length; k += 16) {
    const AA = a, BB = b, CC = c, DD = d;
    a = FF(a, b, c, d, x[k + 0], S11, 0xd76aa478);
    d = FF(d, a, b, c, x[k + 1], S12, 0xe8c7b756);
    c = FF(c, d, a, b, x[k + 2], S13, 0x242070db);
    b = FF(b, c, d, a, x[k + 3], S14, 0xc1bdceee);
    a = FF(a, b, c, d, x[k + 4], S11, 0xf57c0faf);
    d = FF(d, a, b, c, x[k + 5], S12, 0x4787c62a);
    c = FF(c, d, a, b, x[k + 6], S13, 0xa8304613);
    b = FF(b, c, d, a, x[k + 7], S14, 0xfd469501);
    a = FF(a, b, c, d, x[k + 8], S11, 0x698098d8);
    d = FF(d, a, b, c, x[k + 9], S12, 0x8b44f7af);
    c = FF(c, d, a, b, x[k + 10], S13, 0xffff5bb1);
    b = FF(b, c, d, a, x[k + 11], S14, 0x895cd7be);
    a = FF(a, b, c, d, x[k + 12], S11, 0x6b901122);
    d = FF(d, a, b, c, x[k + 13], S12, 0xfd987193);
    c = FF(c, d, a, b, x[k + 14], S13, 0xa679438e);
    b = FF(b, c, d, a, x[k + 15], S14, 0x49b40821);

    a = GG(a, b, c, d, x[k + 1], S21, 0xf61e2562);
    d = GG(d, a, b, c, x[k + 6], S22, 0xc040b340);
    c = GG(c, d, a, b, x[k + 11], S23, 0x265e5a51);
    b = GG(b, c, d, a, x[k + 0], S24, 0xe9b6c7aa);
    a = GG(a, b, c, d, x[k + 5], S21, 0xd62f105d);
    d = GG(d, a, b, c, x[k + 10], S22, 0x2441453);
    c = GG(c, d, a, b, x[k + 15], S23, 0xd8a1e681);
    b = GG(b, c, d, a, x[k + 4], S24, 0xe7d3fbc8);
    a = GG(a, b, c, d, x[k + 9], S21, 0x21e1cde6);
    d = GG(d, a, b, c, x[k + 14], S22, 0xc33707d6);
    c = GG(c, d, a, b, x[k + 3], S23, 0xf4d50d87);
    b = GG(b, c, d, a, x[k + 8], S24, 0x455a14ed);
    a = GG(a, b, c, d, x[k + 13], S21, 0xa9e3e905);
    d = GG(d, a, b, c, x[k + 2], S22, 0xfcefa3f8);
    c = GG(c, d, a, b, x[k + 7], S23, 0x676f02d9);
    b = GG(b, c, d, a, x[k + 12], S24, 0x8d2a4c8a);

    a = HH(a, b, c, d, x[k + 5], S31, 0xfffa3942);
    d = HH(d, a, b, c, x[k + 8], S32, 0x8771f681);
    c = HH(c, d, a, b, x[k + 11], S33, 0x6d9d6122);
    b = HH(b, c, d, a, x[k + 14], S34, 0xfde5380c);
    a = HH(a, b, c, d, x[k + 1], S31, 0xa4beea44);
    d = HH(d, a, b, c, x[k + 4], S32, 0x4bdecfa9);
    c = HH(c, d, a, b, x[k + 7], S33, 0xf6bb4b60);
    b = HH(b, c, d, a, x[k + 10], S34, 0xbebfbc70);
    a = HH(a, b, c, d, x[k + 13], S31, 0x289b7ec6);
    d = HH(d, a, b, c, x[k + 0], S32, 0xeaa127fa);
    c = HH(c, d, a, b, x[k + 3], S33, 0xd4ef3085);
    b = HH(b, c, d, a, x[k + 6], S34, 0x4881d05);
    a = HH(a, b, c, d, x[k + 9], S31, 0xd9d4d039);
    d = HH(d, a, b, c, x[k + 12], S32, 0xe6db99e5);
    c = HH(c, d, a, b, x[k + 15], S33, 0x1fa27cf8);
    b = HH(b, c, d, a, x[k + 2], S34, 0xc4ac5665);

    a = II(a, b, c, d, x[k + 0], S41, 0xf4292244);
    d = II(d, a, b, c, x[k + 7], S42, 0x432aff97);
    c = II(c, d, a, b, x[k + 14], S43, 0xab9423a7);
    b = II(b, c, d, a, x[k + 5], S44, 0xfc93a039);
    a = II(a, b, c, d, x[k + 12], S41, 0x655b59c3);
    d = II(d, a, b, c, x[k + 3], S42, 0x8f0ccc92);
    c = II(c, d, a, b, x[k + 10], S43, 0xffeff47d);
    b = II(b, c, d, a, x[k + 1], S44, 0x85845dd1);
    a = II(a, b, c, d, x[k + 8], S41, 0x6fa87e4f);
    d = II(d, a, b, c, x[k + 15], S42, 0xfe2ce6e0);
    c = II(c, d, a, b, x[k + 6], S43, 0xa3014314);
    b = II(b, c, d, a, x[k + 13], S44, 0x4e0811a1);
    a = II(a, b, c, d, x[k + 4], S41, 0xf7537e82);
    d = II(d, a, b, c, x[k + 11], S42, 0xbd3af235);
    c = II(c, d, a, b, x[k + 2], S43, 0x2ad7d2bb);
    b = II(b, c, d, a, x[k + 9], S44, 0xeb86d391);

    a = addUnsigned(a, AA);
    b = addUnsigned(b, BB);
    c = addUnsigned(c, CC);
    d = addUnsigned(d, DD);
  }
  return (wordToHex(a) + wordToHex(b) + wordToHex(c) + wordToHex(d)).toLowerCase();
}

async function safeRecordHealth(
  supabase: any,
  success: boolean,
  devices: number,
  errorCode: string | null,
  errorMessage: string | null
) {
  try {
    await supabase.rpc("record_sync_health", {
      p_success: success,
      p_devices: devices,
      p_error_code: errorCode,
      p_error_message: errorMessage,
    });
  } catch (e) {
    console.error("Failed to record sync health:", e);
  }
}

// Global cached session token in edge worker isolate memory
let cachedToken: string | null = null;
let tokenExpiresAt = 0;

async function authenticateEtrack(account: string, password: string): Promise<string> {
  const now = Date.now();
  if (cachedToken && now < tokenExpiresAt) {
    return cachedToken;
  }

  const pd = md5(password);
  const tz = -new Date().getTimezoneOffset();
  const loginUrl = new URL("https://app.etrack.vip/LoginService");
  loginUrl.searchParams.set("method", "login");
  loginUrl.searchParams.set("username", account);
  loginUrl.searchParams.set("passwd", pd);
  loginUrl.searchParams.set("logintype", "webcustomer");
  loginUrl.searchParams.set("tzOffset", tz.toString());

  const loginResp = await fetch(loginUrl.toString(), {
    method: "POST",
    headers: {
      "Host": "app.etrack.vip",
      "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)",
      "Accept": "application/json, text/javascript, */*; q=0.01",
      "X-Requested-With": "XMLHttpRequest",
      "Origin": "https://app.etrack.vip",
      "Referer": "https://app.etrack.vip/mobile/",
    },
    signal: AbortSignal.timeout(15000),
  });

  if (!loginResp.ok) {
    throw new Error(`LOGIN_HTTP_${loginResp.status}`);
  }

  const loginText = await loginResp.text();
  let loginJson: any;
  try {
    loginJson = JSON.parse(loginText);
  } catch {
    throw new Error("LOGIN_RESPONSE_NOT_JSON");
  }

  if (loginJson.errorcode !== 0) {
    throw new Error(`LOGIN_ERROR_${loginJson.errorcode}`);
  }

  // Extract session token from Set-Cookie
  const setCookie = loginResp.headers.get("set-cookie") || "";
  let token = "";
  const tokenMatch = setCookie.match(/token=([^;]+)/);
  if (tokenMatch) {
    token = tokenMatch[1];
  }

  if (!token) {
    throw new Error("LOGIN_TOKEN_NOT_FOUND_IN_COOKIE");
  }

  cachedToken = token;
  tokenExpiresAt = now + 12 * 60 * 60 * 1000; // cache for 12 hours (cookie is 24h)
  return token;
}

interface PortalDevice {
  name: string;
  id: string;
}

async function fetchPortalDevices(token: string): Promise<PortalDevice[]> {
  const homeResp = await fetch("https://app.etrack.vip/mobile/?_p=home", {
    method: "GET",
    headers: {
      "Cookie": `token=${token}; username=AmomyBus;`,
      "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)",
      "Referer": "https://app.etrack.vip/mobile/",
    },
    signal: AbortSignal.timeout(15000),
  });

  if (!homeResp.ok) {
    throw new Error(`PORTAL_HOME_HTTP_${homeResp.status}`);
  }

  const html = await homeResp.text();
  const devices: PortalDevice[] = [];
  const dlRegex = /<dl>([\s\S]*?)<\/dl>/g;
  let match;
  while ((match = dlRegex.exec(html)) !== null) {
    const dlContent = match[1];
    const nameMatch = dlContent.match(/<h2><a[^>]*>(.*?)<\/a><\/h2>/);
    const idMatch = dlContent.match(/_p=devices&id=(\d+)/);
    if (nameMatch && idMatch) {
      devices.push({
        name: nameMatch[1].trim(),
        id: idMatch[1].trim(),
      });
    }
  }

  // Fallback defaults for Amomy 1 & Amomy 2 verified IDs if HTML template changes
  if (devices.length === 0) {
    devices.push({ name: "Amomy1", id: "142200" });
    devices.push({ name: "Amomy2", id: "142222" });
  }

  return devices;
}

async function fetchDeviceGpsTelemetry(deviceId: string, token: string): Promise<any> {
  const url = `https://etrack.vip/LocationService?method=deviceAndGpsone&deviceid=${deviceId}&_t=${Date.now()}`;
  const resp = await fetch(url, {
    method: "GET",
    headers: {
      "Cookie": `token=${token};`,
      "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)",
      "Referer": `https://etrack.vip/mobile/itracking.jsp?id=${deviceId}`,
    },
    signal: AbortSignal.timeout(15000),
  });

  if (!resp.ok) {
    throw new Error(`GPS_HTTP_${resp.status}`);
  }

  const json = await resp.json();
  if (json.errorcode !== 0 || !json.records || json.records.length === 0) {
    return null;
  }

  const record = json.records[0];
  const k = json.key || {};

  const lat = record[k.lat !== undefined ? k.lat : 5];
  const lng = record[k.lng !== undefined ? k.lng : 4];
  const speed = record[k.speed !== undefined ? k.speed : 6];
  const course = record[k.course !== undefined ? k.course : 7];
  const gpstime = record[k.gpstime !== undefined ? k.gpstime : 1];
  const systime = record[k.systime !== undefined ? k.systime : 2];
  const imei = record[k.imei !== undefined ? k.imei : 17];
  const name = record[k.device_name !== undefined ? k.device_name : 10];
  const battery = record[k.battery !== undefined ? k.battery : 25];
  const accstatus = record[k.accstatus !== undefined ? k.accstatus : 19];

  return {
    deviceId,
    name: (name || "").toString().trim(),
    imei: (imei || "").toString().trim(),
    latitude: typeof lat === "number" ? lat : parseFloat(lat),
    longitude: typeof lng === "number" ? lng : parseFloat(lng),
    speed: typeof speed === "number" ? speed : parseFloat(speed || "0"),
    heading: typeof course === "number" ? course : parseInt(course || "0", 10),
    gpstime: gpstime ? (typeof gpstime === "number" ? gpstime : parseInt(gpstime, 10)) : null,
    systime: systime ? (typeof systime === "number" ? systime : parseInt(systime, 10)) : null,
    battery: battery ? parseInt(battery.toString().replace("%", ""), 10) : null,
    engineOn: accstatus !== undefined && accstatus !== null ? parseInt(accstatus.toString(), 10) === 1 : null,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

  if (!supabaseUrl || !supabaseServiceKey) {
    return new Response(
      JSON.stringify({ success: false, error: "ENV_CONFIG_MISSING" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false },
  });

  try {
    // 1. Resolve ETrack credentials from secure vault RPC
    let account = Deno.env.get("ETRACK_ACCOUNT") || "";
    let password = Deno.env.get("ETRACK_PASSWORD") || "";

    if (!account || !password) {
      const { data: creds, error: credsError } = await supabase.rpc("get_etrack_credentials");
      if (credsError || !creds || creds.length === 0) {
        await safeRecordHealth(supabase, false, 0, "CREDENTIALS_MISSING", credsError?.message || "Vault error");
        return new Response(
          JSON.stringify({ success: false, error: "ETRACK_CREDENTIALS_MISSING" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      account = creds[0].account;
      password = creds[0].password;
    }

    // 2. Authenticate against official ETrack session endpoint
    let token: string;
    try {
      token = await authenticateEtrack(account, password);
    } catch (authErr: any) {
      // If cached token failed, invalidate and retry once
      cachedToken = null;
      token = await authenticateEtrack(account, password);
    }

    // 3. Fetch active mapped devices from database (STRICT FLEET SCOPE: Amomy 1 & Amomy 2 only)
    const { data: devices, error: devError } = await supabase
      .from("bus_tracking_devices")
      .select("bus_id, provider, provider_device_id, provider_device_name, is_active")
      .eq("provider", "etrack")
      .eq("is_active", true);

    if (devError || !devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ success: true, updated: 0, message: "NO_ACTIVE_ETRACK_DEVICES" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Strictly Amomy 1 and Amomy 2
    const allowedDevices = devices.filter(
      (d: any) =>
        d.provider_device_name === "Amomy1" ||
        d.provider_device_name === "Amomy2" ||
        d.provider_device_id === "865881045820542" ||
        d.provider_device_id === "865881045843551"
    );

    if (allowedDevices.length === 0) {
      return new Response(
        JSON.stringify({ success: true, updated: 0, message: "NO_AMOMY_1_OR_2_MAPPED" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Resolve portal device IDs
    const portalDevices = await fetchPortalDevices(token);

    let updatedCount = 0;
    const sanitizedResults: any[] = [];
    const nowIso = new Date().toISOString();

    for (const allowedDev of allowedDevices) {
      // Match portal device by name or predefined mapping
      let pDev = portalDevices.find(
        (p) =>
          p.name.toLowerCase() === allowedDev.provider_device_name.toLowerCase() ||
          (allowedDev.provider_device_name === "Amomy1" && p.id === "142200") ||
          (allowedDev.provider_device_name === "Amomy2" && p.id === "142222")
      );

      if (!pDev) {
        if (allowedDev.provider_device_name === "Amomy1" || allowedDev.provider_device_id === "865881045820542") {
          pDev = { name: "Amomy1", id: "142200" };
        } else if (allowedDev.provider_device_name === "Amomy2" || allowedDev.provider_device_id === "865881045843551") {
          pDev = { name: "Amomy2", id: "142222" };
        }
      }

      if (!pDev) continue;

      try {
        const tel = await fetchDeviceGpsTelemetry(pDev.id, token);
        if (!tel) continue;

        const lat = tel.latitude;
        const lng = tel.longitude;

        // Telemetry Validation: -90 <= lat <= 90, -180 <= lng <= 180
        if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          console.warn(`Invalid coordinates for ${allowedDev.provider_device_name}: lat=${lat}, lng=${lng}`);
          continue;
        }

        // Timestamp Semantics: recorded_at MUST be genuine hardware event time
        const recordedAt = tel.gpstime ? new Date(tel.gpstime).toISOString() : nowIso;
        const providerServerTime = tel.systime ? new Date(tel.systime).toISOString() : null;

        const heading = isNaN(tel.heading) ? 0 : Math.max(0, Math.min(360, tel.heading));
        const speedKmh = isNaN(tel.speed) ? 0 : Math.max(0, tel.speed);

        // 5. Authoritative Upsert into public.bus_live_locations with source = 'etrack'
        const { error: upsertError } = await supabase
          .from("bus_live_locations")
          .upsert({
            bus_id: allowedDev.bus_id,
            latitude: lat,
            longitude: lng,
            speed_kmh: speedKmh,
            heading: heading,
            gps_recorded_at: recordedAt,
            provider_server_time: providerServerTime,
            battery_pct: isNaN(tel.battery) ? null : tel.battery,
            engine_on: tel.engineOn,
            source: "etrack",
            is_valid: true,
            last_synced_at: nowIso,
            updated_at: nowIso,
          }, { onConflict: "bus_id" });

        if (!upsertError) {
          updatedCount++;

          // 6. Monotonic stop progression recalculation
          try {
            await supabase.rpc("compute_bus_progression", { p_bus_id: allowedDev.bus_id });
          } catch (progErr) {
            console.error("Progression compute error:", progErr);
          }

          // 7. Audit history entry
          try {
            await supabase
              .from("bus_location_history")
              .insert({
                bus_id: allowedDev.bus_id,
                latitude: lat,
                longitude: lng,
                speed_kmh: speedKmh,
                heading: heading,
                gps_recorded_at: recordedAt,
                source: "etrack",
              });
          } catch {}

          const ageSec = Math.floor((Date.now() - new Date(recordedAt).getTime()) / 1000);
          sanitizedResults.push({
            bus_name: allowedDev.provider_device_name,
            bus_id: allowedDev.bus_id,
            latitude: lat,
            longitude: lng,
            speed_kmh: speedKmh,
            heading: heading,
            recorded_at: recordedAt,
            received_at: nowIso,
            source: "etrack",
            freshness: ageSec <= 120 ? "fresh" : "stale",
            age_seconds: ageSec,
          });
        } else {
          console.error("Database upsert error:", upsertError);
        }
      } catch (devTelErr) {
        console.error(`Telemetry fetch error for ${allowedDev.provider_device_name}:`, devTelErr);
      }
    }

    // 8. Record successful sync health
    await safeRecordHealth(supabase, true, updatedCount, null, null);

    return new Response(
      JSON.stringify({
        success: true,
        updated_count: updatedCount,
        synced_at: nowIso,
        devices: sanitizedResults,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    const errMessage = error instanceof Error ? error.message : "UNKNOWN_ERROR";
    console.error("FATAL SYNC EXCEPTION:", error);
    await safeRecordHealth(supabase, false, 0, "EXCEPTION", errMessage);

    return new Response(
      JSON.stringify({ success: false, error: "SYNC_EXCEPTION", message: errMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
