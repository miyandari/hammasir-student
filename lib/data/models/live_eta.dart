import 'package:latlong2/latlong.dart';

import 'package:hammasir_student/core/utils/json_utils.dart';

/// ایستگاه بعدی/قبلی در پاسخ ETA.
class EtaStation {
  const EtaStation({
    required this.stationId,
    required this.name,
    this.etaSeconds,
    this.distanceMeters,
  });

  final int stationId;
  final String name;
  final int? etaSeconds;
  final double? distanceMeters;

  static EtaStation? tryParse(dynamic raw) {
    final map = asMap(raw);
    if (map == null) return null;
    final id = asInt(map['station_id']);
    if (id == null) return null;

    return EtaStation(
      stationId: id,
      name: asString(map['station_name'], 'ایستگاه'),
      etaSeconds: asInt(map['eta_seconds']),
      distanceMeters: asDouble(map['distance_from_vehicle_meters']),
    );
  }
}

/// وضعیت زنده‌ی سفر: موقعیت خودرو و ETA.
class LiveEta {
  const LiveEta({
    this.vehicle,
    this.next,
    this.upcoming = const [],
    this.etaAvailable = false,
    this.gpsStatus,
    this.progressPercent,
  });

  final LatLng? vehicle;
  final EtaStation? next;
  final List<EtaStation> upcoming;
  final bool etaAvailable;

  /// مثلاً online / delayed / offline
  final String? gpsStatus;
  final double? progressPercent;

  bool get gpsOffline => gpsStatus == 'offline';

  /// زمان رسیدن به یک ایستگاه مشخص (بعدی یا یکی از بعدی‌ها).
  int? etaToStation(int stationId) {
    if (next?.stationId == stationId) return next?.etaSeconds;
    for (final item in upcoming) {
      if (item.stationId == stationId) return item.etaSeconds;
    }
    return null;
  }

  LiveEta withVehicle(LatLng point) {
    return LiveEta(
      vehicle: point,
      next: next,
      upcoming: upcoming,
      etaAvailable: etaAvailable,
      gpsStatus: gpsStatus,
      progressPercent: progressPercent,
    );
  }

  factory LiveEta.fromJson(Map<String, dynamic> json) {
    final lat = asDouble(json['vehicle_latitude']);
    final lng = asDouble(json['vehicle_longitude']);

    return LiveEta(
      vehicle: (lat != null && lng != null) ? LatLng(lat, lng) : null,
      next: EtaStation.tryParse(json['next_station']),
      upcoming: [
        for (final item in asMapList(json['upcoming_stations']))
          if (EtaStation.tryParse(item) case final parsed?) parsed,
      ],
      etaAvailable: asBool(json['eta_available']),
      gpsStatus: asNullableString(json['gps_status']),
      progressPercent: asDouble(json['route_progress_percent']),
    );
  }
}
