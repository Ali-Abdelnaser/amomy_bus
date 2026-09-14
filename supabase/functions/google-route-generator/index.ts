import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AnchorPoint {
  id: string;
  sequence: number;
  latitude: number;
  longitude: number;
  is_temporary: boolean;
}

// Haversine distance in meters
function haversineMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000.0;
  const dLat = (lat2 - lat1) * (Math.PI / 180.0);
  const dLon = (lon2 - lon1) * (Math.PI / 180.0);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180.0)) *
      Math.cos(lat2 * (Math.PI / 180.0)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Distance from point p to segment v-w
function distToSegment(
  pLat: number,
  pLng: number,
  vLat: number,
  vLng: number,
  wLat: number,
  wLng: number
): number {
  const l2 = (vLat - wLat) * (vLat - wLat) + (vLng - wLng) * (vLng - wLng);
  if (l2 === 0) return haversineMeters(pLat, pLng, vLat, vLng);
  const t = Math.max(
    0,
    Math.min(
      1,
      ((pLat - vLat) * (wLat - vLat) + (pLng - vLng) * (wLng - vLng)) / l2
    )
  );
  const projLat = vLat + t * (wLat - vLat);
  const projLng = vLng + t * (wLng - vLng);
  return haversineMeters(pLat, pLng, projLat, projLng);
}

// Decode Google Encoded Polyline algorithm
function decodePolyline(encoded: string): Array<{ lat: number; lng: number }> {
  const poly: Array<{ lat: number; lng: number }> = [];
  let index = 0;
  const len = encoded.length;
  let lat = 0;
  let lng = 0;

  while (index < len) {
    let b: number;
    let shift = 0;
    let result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    poly.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }
  return poly;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY");
    if (!apiKey || apiKey.trim() === "") {
      return new Response(
        JSON.stringify({
          error: "CONFIGURATION_ERROR",
          message: "GOOGLE_ROUTES_API_KEY secret is not configured in Supabase Edge Functions environment.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { route_id, direction } = await req.json();
    if (!route_id) {
      return new Response(
        JSON.stringify({ error: "BAD_REQUEST", message: "route_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Resolve route and direction from live public.routes
    const { data: routeData, error: routeError } = await supabase
      .from("routes")
      .select("id, direction")
      .eq("id", route_id)
      .single();

    if (routeError || !routeData) {
      return new Response(
        JSON.stringify({ error: "ROUTE_NOT_FOUND", message: "Route could not be found." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Exact direction matching live schema enum: 'outbound' or 'return'
    const routeDirection = direction
      ? direction.toLowerCase()
      : routeData.direction.toLowerCase();

    // 2. Fetch live route_anchor_points for this route
    const { data: anchors, error: anchorError } = await supabase
      .from("route_anchor_points")
      .select("id, sequence, latitude, longitude, is_temporary, is_active")
      .eq("route_id", route_id)
      .eq("is_active", true)
      .order("sequence", { ascending: true });

    if (anchorError || !anchors || anchors.length < 2) {
      return new Response(
        JSON.stringify({
          error: "INSUFFICIENT_ANCHOR_POINTS",
          message: "Route has fewer than 2 active anchor points.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const origin = {
      location: {
        latLng: {
          latitude: anchors[0].latitude,
          longitude: anchors[0].longitude,
        },
      },
    };

    const destination = {
      location: {
        latLng: {
          latitude: anchors[anchors.length - 1].latitude,
          longitude: anchors[anchors.length - 1].longitude,
        },
      },
    };

    // Use intermediate shaping points (via: true)
    const intermediates = [];
    for (let i = 1; i < anchors.length - 1; i++) {
      intermediates.push({
        via: true,
        location: {
          latLng: {
            latitude: anchors[i].latitude,
            longitude: anchors[i].longitude,
          },
        },
      });
    }

    // 3. Call Google Routes API
    const routesApiUrl = "https://routes.googleapis.com/directions/v2:computeRoutes";
    const requestPayload = {
      origin,
      destination,
      intermediates,
      travelMode: "DRIVE",
      routingPreference: "TRAFFIC_UNAWARE",
      computeAlternativeRoutes: false,
      polylineQuality: "HIGH_QUALITY",
      polylineEncoding: "ENCODED_POLYLINE",
    };

    const routesResponse = await fetch(routesApiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
      },
      body: JSON.stringify(requestPayload),
    });

    if (!routesResponse.ok) {
      const errorText = await routesResponse.text();
      return new Response(
        JSON.stringify({
          error: "ROUTES_API_ERROR",
          status: routesResponse.status,
          message: errorText,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const resJson = await routesResponse.json();
    const primaryRoute = resJson.routes?.[0];
    if (!primaryRoute || !primaryRoute.polyline?.encodedPolyline) {
      return new Response(
        JSON.stringify({
          error: "EMPTY_ROUTE",
          message: "Routes API returned no valid route polyline.",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const encodedPolyline = primaryRoute.polyline.encodedPolyline;
    const distanceMeters = primaryRoute.distanceMeters ?? 0;
    const durationSeconds = parseInt((primaryRoute.duration ?? "0s").replace("s", ""), 10);
    const decodedPoints = decodePolyline(encodedPolyline);

    // 4. Fetch stops for route validation
    const { data: routeStops } = await supabase
      .from("route_stops")
      .select("id, stop_order, stops(id, name_ar, name_en, latitude, longitude)")
      .eq("route_id", route_id)
      .order("stop_order", { ascending: true });

    // Validate stops proximity against generated polyline
    const stopsOver200m: any[] = [];
    const stopValidations: any[] = [];

    if (routeStops && routeStops.length > 0) {
      for (const rs of routeStops) {
        const stop = (rs as any).stops;
        if (!stop || stop.latitude == null || stop.longitude == null) continue;

        let minDist = Infinity;
        for (let j = 0; j < decodedPoints.length - 1; j++) {
          const d = distToSegment(
            stop.latitude,
            stop.longitude,
            decodedPoints[j].lat,
            decodedPoints[j].lng,
            decodedPoints[j + 1].lat,
            decodedPoints[j + 1].lng
          );
          if (d < minDist) minDist = d;
        }

        const report = {
          stop_id: stop.id,
          name_en: stop.name_en,
          name_ar: stop.name_ar,
          stop_order: rs.stop_order,
          distance_meters: Math.round(minDist * 10) / 10,
        };
        stopValidations.push(report);

        if (minDist > 200.0) {
          stopsOver200m.push(report);
        }
      }
    }

    // 5. Version resolution
    const { data: existingVersions } = await supabase
      .from("route_geometries")
      .select("version")
      .eq("route_id", route_id)
      .eq("direction", routeDirection)
      .order("version", { ascending: false })
      .limit(1);

    const nextVersion =
      existingVersions && existingVersions.length > 0
        ? existingVersions[0].version + 1
        : 1;

    // Deactivate previous versions
    await supabase
      .from("route_geometries")
      .update({ is_active: false })
      .eq("route_id", route_id)
      .eq("direction", routeDirection);

    // 6. Insert into live public.route_geometries
    const validationSummary = {
      decoded_points_count: decodedPoints.length,
      stops_count: stopValidations.length,
      stops_over_200m_count: stopsOver200m.length,
      stops_over_200m: stopsOver200m,
      anchors_used: anchors.length,
    };

    const { data: inserted, error: insertError } = await supabase
      .from("route_geometries")
      .insert({
        route_id: route_id,
        direction: routeDirection,
        version: nextVersion,
        polyline_encoded: encodedPolyline,
        polyline_points: decodedPoints,
        distance_meters: distanceMeters,
        duration_seconds: durationSeconds,
        source: "google_routes",
        is_verified: false,
        production_ready: false,
        is_active: true,
        validation_summary: validationSummary,
      })
      .select()
      .single();

    if (insertError) {
      return new Response(
        JSON.stringify({
          error: "DATABASE_INSERT_ERROR",
          message: insertError.message,
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        geometry_id: inserted.id,
        route_id: route_id,
        direction: routeDirection,
        version: nextVersion,
        distance_meters: distanceMeters,
        duration_seconds: durationSeconds,
        decoded_points_count: decodedPoints.length,
        stops_over_200m: stopsOver200m,
        validation_summary: validationSummary,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: "INTERNAL_ERROR", message: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
