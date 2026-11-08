import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/route_summary.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/models/trip_availability.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/reservation_repository.dart';
import 'package:hammasir_student/data/repositories/routing_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';

class ReserveController extends ChangeNotifier with SafeNotifier {
  ReserveController({
    required this.trip,
    required this.service,
    required this.studentId,
    required CatalogRepository catalog,
    required TripRepository trips,
    required ReservationRepository reservations,
    required RoutingRepository routing,
  })  : _catalog = catalog,
        _trips = trips,
        _reservations = reservations,
        _routing = routing;

  final Trip trip;
  final ServiceInfo service;
  final int studentId;

  final CatalogRepository _catalog;
  final TripRepository _trips;
  final ReservationRepository _reservations;
  final RoutingRepository _routing;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<RouteStationInfo> _stops = const [];
  TripAvailability? _availability;
  List<LatLng>? _path;
  int? _stationId;
  bool _submitting = false;

  LoadStatus get status => _status;
  String? get error => _error;
  List<RouteStationInfo> get stops => _stops;
  TripAvailability? get availability => _availability;

  /// مسیر خیابانی؛ تا رسیدن پاسخ مسیریابی (یا در صورت خطا) null است.
  List<LatLng>? get path => _path;
  int? get stationId => _stationId;
  bool get submitting => _submitting;

  /// «سرویس از X به Y»؛ تا رسیدن ایستگاه‌ها نام ثبت‌شده‌ی سرویس.
  String get title => RouteSummary.of(_stops)?.title ?? service.name;

  bool get canSubmit => _stationId != null && !_submitting && !isFull;

  /// رزرو فقط برای صندلی است؛ وقتی جا نیست، سوارشدن فقط در ایستگاه و با تأیید راننده ممکن است.
  bool get isFull {
    final a = _availability;
    return a != null && !a.hasSeat;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _catalog.routeStations(service.routeId),
        _trips.availability(trip.id),
      ]);
      _stops = results[0] as List<RouteStationInfo>;
      _availability = results[1] as TripAvailability?;
      _status = LoadStatus.ready;
      notifyListeners();
      await _loadPath();
      return;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> _loadPath() async {
    final points = [
      for (final info in _stops)
        if (info.station.point case final point?) point,
    ];
    _path = await _routing.drivingPath(points);
    notifyListeners();
  }

  String? stationName(int? id) {
    if (id == null) return null;
    for (final info in _stops) {
      if (info.station.id == id) return info.station.name;
    }
    return null;
  }

  void selectStation(int id) {
    _stationId = id;
    notifyListeners();
  }

  /// موفق: رزرو ساخته‌شده. ناموفق: null و [error] پر می‌شود.
  Future<Reservation?> submit() async {
    final station = _stationId;
    if (station == null || _submitting) return null;

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      return await _reservations.create(
        tripId: trip.id,
        studentId: studentId,
        stationId: station,
        standing: false,
      );
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
