import 'package:flutter/foundation.dart';

import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/reservation_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';
import 'package:hammasir_student/l10n/l10n.dart';

/// یک رزرو همراه با سفر و سرویس آن.
class Booking {
  const Booking({
    required this.reservation,
    required this.trip,
    this.service,
    this.boarded = false,
    this.rated = false,
  });

  final Reservation reservation;
  final Trip trip;
  final ServiceInfo? service;

  /// دانشجو در این سفر واقعاً سوار شده است.
  final bool boarded;

  /// برای این سفر امتیاز ثبت شده است.
  final bool rated;

  String get title => service?.name ?? L10n.t('common.service');

  /// سفر هنوز تمام نشده و رزرو فعال/در انتظار است.
  bool get isUpcoming =>
      reservation.isLiveBooking && !trip.isFinished && !_isStale;

  /// سفری که ساعتش خیلی گذشته ولی هیچ‌وقت بسته نشده (راننده شروع/پایان نزده).
  bool get _isStale {
    final age = DateTime.now().difference(trip.plannedDeparture);
    return age > (trip.isLive ? const Duration(hours: 12) : const Duration(hours: 3));
  }

  /// رزرو لغو شده ولی سفر هنوز باز است؛ می‌توان دوباره رزرو کرد.
  bool get canRebook =>
      reservation.isCancelled && trip.isOpen && service != null;

  /// فقط اگر سفر تمام شده، دانشجو واقعاً سوار شده و هنوز امتیاز نداده است.
  bool get canRate =>
      trip.status == TripStatus.completed &&
      reservation.isActive &&
      boarded &&
      !rated;
}

/// رزروهای من؛ بین «خانه» و «رزروها» مشترک است تا هر صفحه دوباره از سرور نخواند.
class MyTripsStore extends ChangeNotifier with SafeNotifier {
  MyTripsStore({
    required ReservationRepository reservations,
    required TripRepository trips,
    required CatalogRepository catalog,
  })  : _reservations = reservations,
        _trips = trips,
        _catalog = catalog;

  /// حداکثر تعداد رزرو اخیر که برای هر کدام سفر خوانده می‌شود.
  static const int maxLoaded = 40;

  final ReservationRepository _reservations;
  final TripRepository _trips;
  final CatalogRepository _catalog;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  bool _offline = false;
  List<Booking> _bookings = const [];
  Map<int, Station> _stations = const {};
  Future<void>? _inFlight;

  LoadStatus get status => _status;
  String? get error => _error;

  /// آخرین بارگذاری ناموفق بود و داده‌ی قدیمی نمایش داده می‌شود.
  bool get offline => _offline;

  List<Booking> get upcoming {
    final list = _bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.trip.plannedDeparture.compareTo(b.trip.plannedDeparture));
    return list;
  }

  List<Booking> get history {
    final list = _bookings.where((b) => !b.isUpcoming).toList()
      ..sort((a, b) => b.trip.plannedDeparture.compareTo(a.trip.plannedDeparture));
    return list;
  }

  String? stationName(int? id) => id == null ? null : _stations[id]?.name;

  /// نزدیک‌ترین سفر پیش‌رو.
  Booking? get next {
    final list = upcoming;
    return list.isEmpty ? null : list.first;
  }

  /// رزرو فعال/در انتظار برای یک سفر (اگر باشد).
  Booking? forTrip(int tripId) {
    for (final booking in _bookings) {
      if (booking.trip.id == tripId && booking.reservation.isLiveBooking) {
        return booking;
      }
    }
    return null;
  }

  /// درخواست‌های هم‌زمان یکی می‌شوند.
  Future<void> load() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    if (_bookings.isEmpty) {
      _status = LoadStatus.loading;
      notifyListeners();
    }

    try {
      final reservations = await _reservations.mine();
      reservations.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));
      final recent = reservations.take(maxLoaded).toList();

      final tripIds = {for (final r in recent) r.tripId};
      final tripResults = await Future.wait([
        for (final id in tripIds) _tripOrNull(id),
      ]);
      final trips = {
        for (final trip in tripResults)
          if (trip != null) trip.id: trip,
      };

      final boarded = await _idsOrEmpty(_reservations.boardedTripIds);
      final rated = await _idsOrEmpty(_reservations.ratedTripIds);
      final services = await _servicesOrEmpty();
      _stations = await _stationsOrKeep();

      _bookings = [
        for (final r in recent)
          if (trips[r.tripId] case final trip?)
            Booking(
              reservation: r,
              trip: trip,
              service: services[trip.serviceId],
              boarded: boarded.contains(trip.id),
              rated: rated.contains(trip.id),
            ),
      ];
      _status = LoadStatus.ready;
      _error = null;
      _offline = false;
    } on ApiException catch (e) {
      _error = e.message;
      if (_bookings.isEmpty) {
        _status = LoadStatus.error;
      } else {
        _status = LoadStatus.ready;
        _offline = true;
      }
    }

    notifyListeners();
  }

  Future<Trip?> _tripOrNull(int id) async {
    try {
      return await _trips.byId(id);
    } on ApiException {
      return null;
    }
  }

  Future<Set<int>> _idsOrEmpty(Future<Set<int>> Function() load) async {
    try {
      return await load();
    } on ApiException {
      return const {};
    }
  }

  Future<Map<int, ServiceInfo>> _servicesOrEmpty() async {
    try {
      return await _catalog.services();
    } on ApiException {
      return const {};
    }
  }

  Future<Map<int, Station>> _stationsOrKeep() async {
    try {
      return await _catalog.stations();
    } on ApiException {
      return _stations;
    }
  }

  /// لغو رزرو و بارگذاری دوباره.
  Future<void> cancel(int reservationId) async {
    await _reservations.cancel(reservationId);
    await load();
  }
}
