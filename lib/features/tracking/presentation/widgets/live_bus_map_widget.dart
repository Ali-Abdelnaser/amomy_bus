import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/bus_telemetry.dart';
import '../../domain/models/fleet_bus.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/models/route_geometry.dart';
import 'amomy_map_icons.dart';

/// AMOMY Live Bus Map — Google Maps Native Edition.
///
/// Features:
/// - Native [GoogleMap] widget with camera controls and smooth bus tracking
/// - Stop markers rendered as distinct pins (Normal, Passed, Current, Next, Selected)
/// - Bus marker rendered as circular AMOMY blue badge with white bus icon (no heading rotation)
/// - Road-following polyline rendering with split passed/upcoming styling
/// - Safe GPS projection to route for visual split without fabricating GPS
/// - Follow Bus camera tracking with user-pan disengagement
class LiveBusMapWidget extends StatefulWidget {
  final BusTelemetry? telemetry;
  final List<FleetBus>? fleetBuses;
  final List<BusStopModel> routeStops;
  final LiveTrackingStatus status;
  final BusStopModel? selectedStop;
  final ValueChanged<BusStopModel>? onStopTap;
  final ValueChanged<FleetBus>? onFleetBusTap;
  final VoidCallback? onBusTap;
  final bool isCompactPreview;
  final bool followBus;
  final VoidCallback? onPanStart;
  final RouteGeometry? routeGeometry;

  const LiveBusMapWidget({
    super.key,
    this.telemetry,
    this.fleetBuses,
    this.routeStops = const [],
    this.status = LiveTrackingStatus.offline,
    this.selectedStop,
    this.onStopTap,
    this.onFleetBusTap,
    this.onBusTap,
    this.isCompactPreview = false,
    this.followBus = true,
    this.onPanStart,
    this.routeGeometry,
  });

  @visibleForTesting
  static bool shouldRenderStopMarker(BusStopModel stop) =>
      stop.hasCanonicalCoordinates;

  @visibleForTesting
  static List<BusStopModel> markerEligibleStops(
    List<BusStopModel> stops, {
    required bool isCompactPreview,
  }) {
    final eligible = stops.where(shouldRenderStopMarker);
    return isCompactPreview ? eligible.take(4).toList() : eligible.toList();
  }

  @visibleForTesting
  static bool canShowBusMarker({
    required BusTelemetry? telemetry,
    required LiveTrackingStatus status,
  }) {
    return telemetry != null &&
        (status == LiveTrackingStatus.live ||
            status == LiveTrackingStatus.online ||
            status == LiveTrackingStatus.stale ||
            status == LiveTrackingStatus.progressionUnavailable);
  }

  @visibleForTesting
  static BusMapPrivacyState resolveMapStateOnTelemetryChange({
    required LatLng? currentDisplayedPosition,
    required BusTelemetry? oldTelemetry,
    required BusTelemetry? newTelemetry,
    required LiveTrackingStatus status,
  }) {
    if (newTelemetry == null ||
        !canShowBusMarker(telemetry: newTelemetry, status: status)) {
      return const BusMapPrivacyState(
        displayedPosition: null,
        shouldShowMarker: false,
        isCleared: true,
      );
    }
    return BusMapPrivacyState(
      displayedPosition: LatLng(newTelemetry.latitude, newTelemetry.longitude),
      shouldShowMarker: true,
      isCleared: false,
    );
  }

  @override
  State<LiveBusMapWidget> createState() => _LiveBusMapWidgetState();
}

/// State model tracking coordinate privacy lifecycle on LiveBusMapWidget
class BusMapPrivacyState {
  final LatLng? displayedPosition;
  final bool shouldShowMarker;
  final bool isCleared;

  const BusMapPrivacyState({
    required this.displayedPosition,
    required this.shouldShowMarker,
    required this.isCleared,
  });
}

class _LiveBusMapWidgetState extends State<LiveBusMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(31.0379, 31.3815);
  bool _isMapReady = false;
  bool _initialCameraFitted = false;
  String? _lastLocale;
  late final CameraPosition _initialCameraPosition;

  // ── Gestures & Performance Guard ──────────────────────────────────────────
  bool _isPointerDown = false;
  bool _isCameraMoving = false;
  bool _isProgrammaticCameraMove = false;
  bool _pendingPolylineRebuild = false;

  // ── Smooth Bus Interpolation ──────────────────────────────────────────────
  LatLng? _displayedPosition;
  late AnimationController _positionController;
  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  DateTime? _lastTelemetryRecordedAt;
  DateTime? _lastCameraMoveTime;
  DateTime? _lastPolylineSplitTime;

  // ── Marker & Polyline Cache ───────────────────────────────────────────────
  BitmapDescriptor? _busMarkerIcon;
  BitmapDescriptor? _pinNormalIcon;
  BitmapDescriptor? _pinPassedIcon;
  BitmapDescriptor? _pinCurrentIcon;
  BitmapDescriptor? _pinNextIcon;
  BitmapDescriptor? _pinSelectedIcon;
  BitmapDescriptor? _pinSelectedLastIcon;
  BitmapDescriptor? _pinSelectedNextIcon;

  Set<Marker> _stopMarkers = {};
  Marker? _busMarker;
  Set<Marker> _fleetBusMarkers = {};
  Set<Marker> _combinedMarkers = {};
  Set<Polyline> _cachedPolylines = {};

  @override
  void initState() {
    super.initState();

    // Initial position seed
    final t = widget.telemetry;
    if (t != null && t.hasValidCoordinates) {
      _displayedPosition = LatLng(t.latitude, t.longitude);
      _lastTelemetryRecordedAt = t.gpsRecordedAt;
    }

    final firstCanonicalStop = widget.routeStops
        .cast<BusStopModel?>()
        .firstWhere(
          (s) => s != null && LiveBusMapWidget.shouldRenderStopMarker(s),
          orElse: () => null,
        );
    final initialCenter =
        _displayedPosition ??
        (firstCanonicalStop != null
            ? LatLng(
                firstCanonicalStop.latitude!,
                firstCanonicalStop.longitude!,
              )
            : _defaultCenter);

    _initialCameraPosition = CameraPosition(
      target: initialCenter,
      zoom: widget.isCompactPreview ? 14.6 : 14.4,
    );

    _resolveIcons();
    _rebuildStopMarkers();
    _updateBusMarker(_displayedPosition);
    _initMarkerIcons();

    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..addListener(_onPositionTick);

    _rebuildPolylines();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_lastLocale != locale) {
      _lastLocale = locale;
      _rebuildStopMarkers();
    }
  }

  Future<void> _initMarkerIcons() async {
    await AmomyMapIcons.preloadAllIcons();
    _resolveIcons();
    _rebuildStopMarkers();
    _updateBusMarker(_displayedPosition);
    if (mounted) setState(() {});
  }

  void _resolveIcons() {
    final busState = _resolveBusVisualState();
    _busMarkerIcon =
        AmomyMapIcons.getCachedBusIcon(busState) ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    _pinNormalIcon =
        AmomyMapIcons.getCachedStopIcon(StopPinVisualState.normal) ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _pinPassedIcon = AmomyMapIcons.getCachedStopIcon(StopPinVisualState.passed);
    _pinCurrentIcon = AmomyMapIcons.getCachedStopIcon(
      StopPinVisualState.current,
    );
    _pinNextIcon = AmomyMapIcons.getCachedStopIcon(StopPinVisualState.next);
    _pinSelectedIcon = AmomyMapIcons.getCachedStopIcon(
      StopPinVisualState.selected,
    );
    _pinSelectedLastIcon = AmomyMapIcons.getCachedStopIcon(
      StopPinVisualState.selectedLast,
    );
    _pinSelectedNextIcon = AmomyMapIcons.getCachedStopIcon(
      StopPinVisualState.selectedNext,
    );
  }

  BusMarkerVisualState _resolveBusVisualState() {
    if (widget.status == LiveTrackingStatus.progressionUnavailable) {
      return BusMarkerVisualState.reconnecting;
    }
    final isQa =
        widget.status == LiveTrackingStatus.qaPreview ||
        widget.telemetry?.source == 'qa';
    if (isQa) return BusMarkerVisualState.qa;

    if (widget.status == LiveTrackingStatus.offline ||
        widget.status == LiveTrackingStatus.assignmentPending ||
        widget.status == LiveTrackingStatus.tripNotActive ||
        widget.status == LiveTrackingStatus.outsideTrackingWindow) {
      return BusMarkerVisualState.offline;
    }

    final isStale =
        widget.status == LiveTrackingStatus.stale ||
        (widget.telemetry?.isStale ?? false);
    if (isStale) return BusMarkerVisualState.reconnecting;

    final isAtStop =
        widget.telemetry?.progressState == 'at_stop' ||
        (widget.telemetry != null &&
            !widget.telemetry!.isMoving &&
            widget.telemetry!.currentStopId != null);
    if (isAtStop) return BusMarkerVisualState.atStop;

    return BusMarkerVisualState.live;
  }

  void _rebuildStopMarkers() {
    if (_pinNormalIcon == null) {
      _resolveIcons();
    }
    _pinNormalIcon ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );

    final displayStops = LiveBusMapWidget.markerEligibleStops(
      widget.routeStops,
      isCompactPreview: widget.isCompactPreview,
    );

    final Set<Marker> newStopMarkers = {};
    for (final stop in displayStops) {
      final isCurrent = stop.semanticState == TrackingStopSemanticState.active;
      final isNext = stop.semanticState == TrackingStopSemanticState.next;
      final isSelected = widget.selectedStop?.id == stop.id;
      final isPassed = stop.semanticState == TrackingStopSemanticState.passed;

      BitmapDescriptor icon = _pinNormalIcon!;
      Offset anchor = AmomyMapIcons.normalPinAnchor;

      if (isSelected) {
        anchor = AmomyMapIcons.selectedPinAnchor;
        if (isCurrent && _pinSelectedLastIcon != null) {
          icon = _pinSelectedLastIcon!;
        } else if (isNext && _pinSelectedNextIcon != null) {
          icon = _pinSelectedNextIcon!;
        } else if (_pinSelectedIcon != null) {
          icon = _pinSelectedIcon!;
        }
      } else if (isCurrent && _pinCurrentIcon != null) {
        icon = _pinCurrentIcon!;
      } else if (isNext && _pinNextIcon != null) {
        icon = _pinNextIcon!;
      } else if (isPassed && _pinPassedIcon != null) {
        icon = _pinPassedIcon!;
      }

      int zIndex = 10;
      if (isSelected) {
        zIndex = 200;
      } else if (isCurrent) {
        zIndex = 150;
      } else if (isNext) {
        zIndex = 140;
      } else if (isPassed) {
        zIndex = 5;
      } else {
        zIndex = 10;
      }

      newStopMarkers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude!, stop.longitude!),
          icon: icon,
          anchor: anchor,
          zIndexInt: zIndex,
          infoWindow: InfoWindow(
            title: stop.localizedName(_lastLocale ?? 'ar'),
          ),
          onTap: () => widget.onStopTap?.call(stop),
        ),
      );
    }

    _stopMarkers = newStopMarkers;
    _updateCombinedMarkers();
  }

  void _updateBusMarker(LatLng? pos) {
    if (_busMarkerIcon == null) {
      _resolveIcons();
    }
    final canShowVehicle = LiveBusMapWidget.canShowBusMarker(
      telemetry: widget.telemetry,
      status: widget.status,
    );
    final busCoord = canShowVehicle
        ? (pos ??
              LatLng(widget.telemetry!.latitude, widget.telemetry!.longitude))
        : null;
    if (busCoord != null && _busMarkerIcon != null) {
      _busMarker = Marker(
        markerId: const MarkerId('active_bus'),
        position: busCoord,
        icon: _busMarkerIcon!,
        anchor: AmomyMapIcons.busMarkerAnchor,
        rotation: 0.0, // Non-rotating upright marker
        zIndexInt: 999,
        onTap: widget.onBusTap,
      );
    } else {
      _busMarker = null;
    }

    // Render fleet buses if provided
    final fleet = widget.fleetBuses;
    if (fleet != null && fleet.isNotEmpty && _busMarkerIcon != null) {
      final Set<Marker> newFleetMarkers = {};
      for (final bus in fleet) {
        // Only buses with valid GPS locations
        if (bus.hasValidCoordinates) {
          final busLatLng = LatLng(bus.latitude!, bus.longitude!);
          newFleetMarkers.add(
            Marker(
              markerId: MarkerId('fleet_bus_${bus.busId}'),
              position: busLatLng,
              icon: _busMarkerIcon!,
              anchor: AmomyMapIcons.busMarkerAnchor,
              rotation: 0.0,
              infoWindow: bus.label.isNotEmpty
                  ? InfoWindow(title: bus.label)
                  : InfoWindow.noText,
              onTap: () => widget.onFleetBusTap?.call(bus),
            ),
          );
        }
      }
      _fleetBusMarkers = newFleetMarkers;
    } else {
      _fleetBusMarkers = {};
    }

    _updateCombinedMarkers();
  }

  void _updateCombinedMarkers() {
    _combinedMarkers = {
      ..._stopMarkers,
      ?_busMarker,
      ..._fleetBusMarkers,
    };
  }

  void _rebuildPolylines() {
    final busCoord = widget.telemetry != null
        ? (_displayedPosition ??
              LatLng(widget.telemetry!.latitude, widget.telemetry!.longitude))
        : null;

    final Set<Polyline> newPolylines = {};
    final geom = widget.routeGeometry;

    // Palette constants for Route Visual Hierarchy
    const passedColor = Color(0xFFAEB7C2); // Muted silver/gray
    const upcomingBlue = AppColors.primary; // AMOMY primary blue (#01589F)
    const nextAccentYellow = Color(0xFFFFC928); // AMOMY Yellow
    final casingColor = Colors.white.withValues(alpha: 0.85);

    if (geom != null && geom.points.length >= 2) {
      // Authoritative road-following geometry from Google Routes
      final polyPoints = geom.points;

      if (busCoord != null &&
          (widget.status == LiveTrackingStatus.live ||
              widget.status == LiveTrackingStatus.online)) {
        final split = RouteGeometryEngine.splitPolylineByBus(
          polyline: polyPoints,
          busLocation: busCoord,
        );

        // 1. PASSED ROUTE: muted silver/gray (#AEB7C2), lower priority
        if (split.passed.length >= 2) {
          newPolylines.add(
            Polyline(
              polylineId: const PolylineId('route_passed'),
              points: split.passed,
              color: passedColor,
              width: 4,
              zIndex: 1,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }

        if (split.upcoming.length >= 2) {
          // 2. SUBTLE LIGHT OUTLINE beneath active route to separate from roads
          newPolylines.add(
            Polyline(
              polylineId: const PolylineId('route_upcoming_casing'),
              points: split.upcoming,
              color: casingColor,
              width: 7,
              zIndex: 2,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );

          // 3. NEXT ROUTE SEGMENT ACCENT (bus to next stop in #FFC928)
          bool hasNextSegmentAccent = false;
          final nextStopId = widget.telemetry?.nextStopId;
          if (nextStopId != null) {
            BusStopModel? nextStop;
            for (final s in widget.routeStops) {
              if (s.id == nextStopId &&
                  LiveBusMapWidget.shouldRenderStopMarker(s)) {
                nextStop = s;
                break;
              }
            }

            if (nextStop != null) {
              final nextLoc = LatLng(nextStop.latitude!, nextStop.longitude!);
              int closestSeg = -1;
              double minD = double.infinity;
              LatLng? nextStopProj;

              for (int i = 0; i < split.upcoming.length - 1; i++) {
                final v = split.upcoming[i];
                final w = split.upcoming[i + 1];
                final dLat = w.latitude - v.latitude;
                final dLng = w.longitude - v.longitude;
                final l2 = dLat * dLat + dLng * dLng;
                if (l2 == 0) continue;

                final t =
                    (((nextLoc.latitude - v.latitude) * dLat +
                                (nextLoc.longitude - v.longitude) * dLng) /
                            l2)
                        .clamp(0.0, 1.0);

                final proj = LatLng(
                  v.latitude + t * dLat,
                  v.longitude + t * dLng,
                );
                final d = RouteGeometryEngine.distanceMeters(nextLoc, proj);
                if (d < minD) {
                  minD = d;
                  closestSeg = i;
                  nextStopProj = proj;
                }
              }

              // Only if next stop is along upcoming corridor (< 150m) and ahead of bus
              if (minD <= 150.0 && closestSeg >= 0 && nextStopProj != null) {
                final nextSegPoints = <LatLng>[
                  ...split.upcoming.sublist(0, closestSeg + 1),
                  nextStopProj,
                ];
                final remainingPoints = <LatLng>[
                  nextStopProj,
                  ...split.upcoming.sublist(closestSeg + 1),
                ];

                final segmentDist = RouteGeometryEngine.distanceMeters(
                  nextSegPoints.first,
                  nextSegPoints.last,
                );

                if (nextSegPoints.length >= 2 && segmentDist > 15.0) {
                  hasNextSegmentAccent = true;
                  newPolylines.add(
                    Polyline(
                      polylineId: const PolylineId('route_next_segment'),
                      points: nextSegPoints,
                      color: nextAccentYellow,
                      width: 5,
                      zIndex: 4,
                      jointType: JointType.round,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                    ),
                  );

                  if (remainingPoints.length >= 2) {
                    newPolylines.add(
                      Polyline(
                        polylineId: const PolylineId('route_upcoming'),
                        points: remainingPoints,
                        color: upcomingBlue,
                        width: 5,
                        zIndex: 3,
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                      ),
                    );
                  }
                }
              }
            }
          }

          // If next-segment accent was not applied, render full upcoming in blue
          if (!hasNextSegmentAccent) {
            newPolylines.add(
              Polyline(
                polylineId: const PolylineId('route_upcoming'),
                points: split.upcoming,
                color: upcomingBlue,
                width: 5,
                zIndex: 3,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
          }
        }
      } else {
        // Entire upcoming route without bus split
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('route_full_casing'),
            points: polyPoints,
            color: casingColor,
            width: 7,
            zIndex: 2,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('route_full'),
            points: polyPoints,
            color: upcomingBlue,
            width: 5,
            zIndex: 3,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    } else {
      // Per contract: Do NOT fabricate a route polyline or connect stops with straight lines.
      // If route geometry is null, handle gracefully without creating artificial polylines.
    }

    _cachedPolylines = newPolylines;
  }

  @override
  void dispose() {
    _positionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onPositionTick() {
    if (_latTween == null || _lngTween == null) return;
    final newPos = LatLng(
      _latTween!.evaluate(_positionController),
      _lngTween!.evaluate(_positionController),
    );
    _displayedPosition = newPos;

    // Fast-path: only update the bus marker position while reusing all 34 cached stop markers
    if (_busMarkerIcon != null) {
      _busMarker = Marker(
        markerId: const MarkerId('active_bus'),
        position: newPos,
        icon: _busMarkerIcon!,
        anchor: AmomyMapIcons.busMarkerAnchor,
        rotation: 0.0,
        zIndexInt: 999,
        onTap: widget.onBusTap,
      );
      _updateCombinedMarkers();
    }

    final now = DateTime.now();

    // Throttled route polyline split update (every 2 seconds)
    if (_lastPolylineSplitTime == null ||
        now.difference(_lastPolylineSplitTime!).inMilliseconds >= 2000) {
      _lastPolylineSplitTime = now;
      if (_isCameraMoving || _isPointerDown) {
        _pendingPolylineRebuild = true;
      } else {
        _rebuildPolylines();
      }
    }

    // Critical Rule A: Do NOT call setState continuously while user is gesturing/moving camera
    if (!_isCameraMoving && !_isPointerDown) {
      if (mounted) {
        setState(() {});
      }
    }

    // Camera following: throttled, paused while user is touching/moving the map
    if (widget.followBus &&
        _mapController != null &&
        !_isCameraMoving &&
        !_isPointerDown) {
      if (_lastCameraMoveTime == null ||
          now.difference(_lastCameraMoveTime!).inMilliseconds >= 800) {
        _lastCameraMoveTime = now;
        _isProgrammaticCameraMove = true;
        _mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
      }
    }
  }

  void _animateToPosition(BusTelemetry newTel) {
    if (!newTel.hasValidCoordinates) return;
    final newPos = LatLng(newTel.latitude, newTel.longitude);

    if (_displayedPosition == null) {
      _displayedPosition = newPos;
      _updateBusMarker(newPos);
      _lastTelemetryRecordedAt = newTel.gpsRecordedAt;
      if (mounted) setState(() {});
      if (widget.followBus &&
          _mapController != null &&
          !_isCameraMoving &&
          !_isPointerDown) {
        _isProgrammaticCameraMove = true;
        _mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
      }
      return;
    }

    final fromPos = _displayedPosition!;
    final prevTime =
        _lastTelemetryRecordedAt ??
        newTel.gpsRecordedAt.subtract(const Duration(seconds: 10));
    final elapsed = newTel.gpsRecordedAt.difference(prevTime).abs();
    _lastTelemetryRecordedAt = newTel.gpsRecordedAt;

    final animMs = (elapsed.inMilliseconds * 0.9).clamp(3000, 12000).toInt();
    _latTween = Tween<double>(begin: fromPos.latitude, end: newPos.latitude);
    _lngTween = Tween<double>(begin: fromPos.longitude, end: newPos.longitude);
    _positionController
      ..duration = Duration(milliseconds: animMs)
      ..forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant LiveBusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldTel = oldWidget.telemetry;
    final newTel = widget.telemetry;

    if (newTel != null &&
        (oldTel == null ||
            oldTel.latitude != newTel.latitude ||
            oldTel.longitude != newTel.longitude)) {
      _animateToPosition(newTel);
    } else if (newTel == null &&
        (oldTel != null || _displayedPosition != null)) {
      _positionController.stop();
      _latTween = null;
      _lngTween = null;
      _lastTelemetryRecordedAt = null;
      _displayedPosition = null;
      _busMarker = null;
      _updateCombinedMarkers();
      _rebuildPolylines();
      if (mounted) setState(() {});
    }

    if (widget.followBus &&
        !oldWidget.followBus &&
        widget.telemetry != null &&
        _displayedPosition != null &&
        !_isCameraMoving &&
        !_isPointerDown) {
      _isProgrammaticCameraMove = true;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_displayedPosition!),
      );
    }

    final statusChanged = widget.status != oldWidget.status;
    final stopsChanged = widget.routeStops != oldWidget.routeStops;
    final selectedChanged = widget.selectedStop != oldWidget.selectedStop;
    final compactChanged =
        widget.isCompactPreview != oldWidget.isCompactPreview;
    final stopIdChanged =
        oldTel?.currentStopId != newTel?.currentStopId ||
        oldTel?.nextStopId != newTel?.nextStopId;

    final fleetChanged = widget.fleetBuses != oldWidget.fleetBuses;

    if (statusChanged) {
      _resolveIcons();
    }

    if (statusChanged ||
        stopsChanged ||
        selectedChanged ||
        compactChanged ||
        stopIdChanged ||
        fleetChanged) {
      _rebuildStopMarkers();
      _updateBusMarker(_displayedPosition);
    }

    final geomChanged = widget.routeGeometry != oldWidget.routeGeometry;
    final orderChanged = oldTel?.currentStopOrder != newTel?.currentStopOrder;
    if (geomChanged || stopsChanged || orderChanged) {
      _rebuildPolylines();
    }

    // Camera fitting on initial stops load or fleet buses load
    if (!widget.isCompactPreview &&
        !_initialCameraFitted &&
        _isMapReady) {
      final stopsWithCoords = widget.routeStops
          .where(LiveBusMapWidget.shouldRenderStopMarker)
          .toList();
      if (stopsWithCoords.isNotEmpty) {
        _initialCameraFitted = true;
        _fitCameraToStops(stopsWithCoords);
      } else if (widget.fleetBuses != null && widget.fleetBuses!.isNotEmpty) {
        final busesWithCoords = widget.fleetBuses!
            .where((b) => b.hasValidCoordinates)
            .toList();
        if (busesWithCoords.isNotEmpty) {
          _initialCameraFitted = true;
          _fitCameraToFleetBuses(busesWithCoords);
        }
      }
    }
  }

  void _fitCameraToFleetBuses(List<FleetBus> buses) {
    if (_mapController == null || buses.isEmpty) return;
    _isProgrammaticCameraMove = true;

    double minLat = buses.first.latitude!;
    double maxLat = buses.first.latitude!;
    double minLng = buses.first.longitude!;
    double maxLng = buses.first.longitude!;

    for (final b in buses) {
      if (b.latitude! < minLat) minLat = b.latitude!;
      if (b.latitude! > maxLat) maxLat = b.latitude!;
      if (b.longitude! < minLng) minLng = b.longitude!;
      if (b.longitude! > maxLng) maxLng = b.longitude!;
    }

    if (minLat == maxLat && minLng == maxLng) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 14.6),
      );
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48.0,
      ),
    );
  }

  void _fitCameraToStops(List<BusStopModel> stops) {
    if (_mapController == null || stops.isEmpty) return;

    _isProgrammaticCameraMove = true;

    double minLat = stops.first.latitude!;
    double maxLat = stops.first.latitude!;
    double minLng = stops.first.longitude!;
    double maxLng = stops.first.longitude!;

    for (final s in stops) {
      if (s.latitude! < minLat) minLat = s.latitude!;
      if (s.latitude! > maxLat) maxLat = s.latitude!;
      if (s.longitude! < minLng) minLng = s.longitude!;
      if (s.longitude! > maxLng) maxLng = s.longitude!;
    }

    // Include bus location only if telemetry is valid and reasonably close to route bounding box (< ~0.05 deg buffer)
    if (widget.telemetry != null && _displayedPosition != null) {
      final busLat = _displayedPosition!.latitude;
      final busLng = _displayedPosition!.longitude;
      const buffer = 0.05;
      if (busLat >= minLat - buffer &&
          busLat <= maxLat + buffer &&
          busLng >= minLng - buffer &&
          busLng <= maxLng + buffer) {
        if (busLat < minLat) minLat = busLat;
        if (busLat > maxLat) maxLat = busLat;
        if (busLng < minLng) minLng = busLng;
        if (busLng > maxLng) maxLng = busLng;
      }
    }

    if (minLat == maxLat && minLng == maxLng) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 14.6),
      );
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isQaPreview =
        widget.status == LiveTrackingStatus.qaPreview ||
        widget.telemetry?.source == 'qa';
    final locale = Localizations.localeOf(context).languageCode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isCompactPreview ? 18 : 0),
      child: Stack(
        children: [
          // Neutral skeleton background behind map during initial load (#F1F3F5)
          Container(color: const Color(0xFFF1F3F5)),

          // Native GoogleMap Widget wrapped in Listener for touch gesture detection
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _isPointerDown = true,
            onPointerUp: (_) => _isPointerDown = false,
            onPointerCancel: (_) => _isPointerDown = false,
            child: Builder(
              builder: (context) {
                return GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  markers: _combinedMarkers,
                  polylines: _cachedPolylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  rotateGesturesEnabled:
                      false, // Upright transit map orientation
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  padding: EdgeInsets.only(
                    bottom: widget.isCompactPreview
                        ? 0
                        : 36, // Ensure Google attribution visibility
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() => _isMapReady = true);
                    if (widget.routeStops.isNotEmpty &&
                        !widget.isCompactPreview) {
                      final stopsWithCoords = widget.routeStops
                          .where(LiveBusMapWidget.shouldRenderStopMarker)
                          .toList();
                      if (stopsWithCoords.isNotEmpty) {
                        _fitCameraToStops(stopsWithCoords);
                      }
                    }
                  },
                  onCameraMoveStarted: () {
                    _isCameraMoving = true;
                    if (!_isProgrammaticCameraMove) {
                      // User-initiated movement: pause follow bus
                      widget.onPanStart?.call();
                    }
                  },
                  onCameraMove: (position) {
                    // Critical Rule A:
                    // DO NOT call setState continuously
                    // DO NOT rebuild markers
                    // DO NOT rebuild polylines
                    // DO NOT generate icons
                    // DO NOT perform expensive calculations
                  },
                  onCameraIdle: () {
                    _isCameraMoving = false;
                    _isProgrammaticCameraMove = false;
                    // Critical Rule C: Perform non-critical UI updates only after gesture ends
                    if (_pendingPolylineRebuild) {
                      _pendingPolylineRebuild = false;
                      _rebuildPolylines();
                      if (mounted) setState(() {});
                    } else if (mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),

          // QA Preview indicator
          if (isQaPreview && !widget.isCompactPreview)
            Positioned(
              top: 86,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      locale == 'ar'
                          ? 'معاينة تجريبية للمسار'
                          : 'QA Route Preview',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
