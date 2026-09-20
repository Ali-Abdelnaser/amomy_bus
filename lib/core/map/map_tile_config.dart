import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Centralized map tile provider abstraction for AMOMY tracking views.
///
/// All tracking widgets must read [MapTileConfig.activeConfig] — never
/// scatter tile URLs across widgets.
///
/// Production: Stadia Maps Alidade Smooth with API key authentication.
/// Fallback: OpenStreetMap Standard (DEBUG ONLY).
/// Release Safety: In release mode without a Stadia key, falls back gracefully
/// to a controlled unavailable state without silently spamming public OSM.
class MapTileConfig {
  final String tileUrl;
  final String attribution;
  final String userAgentPackageName;
  final double maxZoom;
  final double minZoom;
  final List<String> subdomains;
  final bool retinaMode;
  final bool isAvailable;

  const MapTileConfig({
    required this.tileUrl,
    required this.attribution,
    required this.userAgentPackageName,
    this.maxZoom = 19,
    this.minZoom = 3,
    this.subdomains = const [],
    this.retinaMode = false,
    this.isAvailable = true,
  });

  /// Stadia Maps Alidade Smooth raster tiles (Production).
  /// Modern, subtle cartography tailored for transit overlays and markers.
  static MapTileConfig productionStadia(String apiKey) {
    final query = apiKey.isNotEmpty ? '?api_key=$apiKey' : '';
    return MapTileConfig(
      tileUrl:
          'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png$query',
      attribution: '© Stadia Maps © OpenMapTiles © OpenStreetMap contributors',
      userAgentPackageName: 'com.amomy.bus',
      maxZoom: 20,
      minZoom: 3,
      retinaMode: true,
      isAvailable: apiKey.isNotEmpty || !kReleaseMode,
    );
  }

  /// OpenStreetMap Standard raster tiles (DEBUG/Dev Fallback only).
  /// Never intended as the primary production provider.
  static const MapTileConfig fallbackOsm = MapTileConfig(
    tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    userAgentPackageName: 'com.amomy.bus',
    maxZoom: 19,
    minZoom: 3,
    isAvailable: true,
  );

  /// Controlled unavailable state when release mode is running without an API key.
  static const MapTileConfig unavailableRelease = MapTileConfig(
    tileUrl: '',
    attribution: '© Stadia Maps © OpenMapTiles © OpenStreetMap',
    userAgentPackageName: 'com.amomy.bus',
    maxZoom: 19,
    minZoom: 3,
    isAvailable: false,
  );

  /// Resolve active provider according to environment & API key readiness.
  ///
  /// Priority:
  /// 1. If [AppConfig.stadiaMapsApiKey] is configured → Use Stadia Maps Alidade Smooth.
  /// 2. If no key and running in [kReleaseMode] → Return [unavailableRelease] (prevent silent OSM usage).
  /// 3. If no key in debug/profile → Return [fallbackOsm] for developer convenience.
  static MapTileConfig resolveActiveConfig({
    String? explicitApiKey,
    bool? isReleaseModeOverride,
  }) {
    final release = isReleaseModeOverride ?? kReleaseMode;
    String key = explicitApiKey ?? '';
    if (key.isEmpty) {
      try {
        key = AppConfig.instance.stadiaMapsApiKey;
      } catch (_) {
        key = '';
      }
    }

    if (key.isNotEmpty) {
      return productionStadia(key);
    }

    if (release) {
      return unavailableRelease;
    }

    return fallbackOsm;
  }

  /// Currently active configuration used across tracking maps.
  static MapTileConfig get activeConfig => resolveActiveConfig();
}
