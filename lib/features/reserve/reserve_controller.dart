import 'package:flutter/foundation.dart';

import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/models/trip_availability.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/reservation_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';

class ReserveController extends ChangeNotifier with SafeNotifier {
  ReserveController({
    required this.trip,
    required this.service,
    required this.studentId,
    required CatalogRepository catalog,
    required TripRepository trips,
    required ReservationRepository reservations,
  })  : _catalog = catalog,
        _trips = trips,
        _reservations = reservations;

  final Trip trip;
  final ServiceInfo service;
  final int studentId;

  final CatalogRepository _catalog;
  final TripRepository _trips;
  final ReservationRepository _reservations;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<RouteStationInfo> _stops = const [];
  TripAvailability? _availability;
  int? _stationId;
  bool _standing = false;
  bool _submitting = false;

  LoadStatus get status => _status;
  String? get error => _error;
  List<RouteStationInfo> get stops => _stops;
  TripAvailability? get availability => _availability;
  int? get stationId => _stationId;
  bool get standing => _standing;
  bool get submitting => _submitting;

  bool get canSubmit => _stationId != null && !_submitting;

  /// ظرفیت پر است و رزرو به لیست انتظار می‌رود.
  bool get willBeWaitlisted {
    final a = _availability;
    if (a == null) return false;
    return _standing ? !a.hasStanding : !a.hasSeat;
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
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  void selectStation(int id) {
    _stationId = id;
    notifyListeners();
  }

  void selectStanding(bool value) {
    if (value && !trip.allowStanding) return;
    _standing = value;
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
        standing: _standing,
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
