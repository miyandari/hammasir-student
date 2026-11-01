import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_student/core/config/app_config.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/data/models/live_eta.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/tracking_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';

/// وضعیت یک سفر و ردیابی زنده.
///
/// موقعیت لحظه‌ای از WebSocket می‌آید؛ هر ۱۵ ثانیه هم وضعیت سفر و ETA از
/// HTTP تازه می‌شود. اگر WebSocket قطع شود، همین polling کار را ادامه می‌دهد.
class TripController extends ChangeNotifier with SafeNotifier {
  TripController({
    required this.tripId,
    required TripRepository trips,
    required CatalogRepository catalog,
    required TrackingRepository tracking,
  })  : _trips = trips,
        _catalog = catalog,
        _tracking = tracking;

  static const int _maxSocketAttempts = 3;

  final int tripId;
  final TripRepository _trips;
  final CatalogRepository _catalog;
  final TrackingRepository _tracking;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Trip? _trip;
  ServiceInfo? _service;
  List<RouteStationInfo> _stops = const [];
  LiveEta? _eta;
  LatLng? _vehicle;
  bool _stale = false;

  Timer? _timer;
  StreamSubscription<LatLng>? _socket;
  int _socketAttempts = 0;
  bool _polling = false;

  LoadStatus get status => _status;
  String? get error => _error;
  Trip? get trip => _trip;
  ServiceInfo? get service => _service;
  List<RouteStationInfo> get stops => _stops;
  LiveEta? get eta => _eta;

  /// آخرین موقعیت شناخته‌شده‌ی خودرو.
  LatLng? get vehicle => _vehicle;

  /// آخرین به‌روزرسانی ناموفق بود (قطع اینترنت).
  bool get stale => _stale;

  Future<void> start() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final trip = await _trips.byId(tripId);
      _trip = trip;

      final services = await _catalog.services();
      _service = services[trip.serviceId];

      final routeId = _service?.routeId;
      if (routeId != null) {
        try {
          _stops = await _catalog.routeStations(routeId);
        } on ApiException {
          _stops = const [];
        }
      }

      _status = LoadStatus.ready;
      notifyListeners();

      await _refreshLive(trip);
      _timer = Timer.periodic(AppConfig.livePollInterval, (_) => _tick());
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
      notifyListeners();
    }
  }

  Future<void> _tick() async {
    if (_polling || isDisposed) return;
    _polling = true;

    try {
      final trip = await _trips.byId(tripId);
      _trip = trip;
      _stale = false;
      await _refreshLive(trip);

      if (trip.isFinished) {
        _stopLive();
        _timer?.cancel();
        _timer = null;
      }
    } on ApiException {
      _stale = true;
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  Future<void> _refreshLive(Trip trip) async {
    if (!trip.isLive) return;

    try {
      final eta = await _trips.eta(tripId);
      if (eta != null) {
        _eta = eta;
        _vehicle = eta.vehicle ?? _vehicle;
      }
      _vehicle ??= await _trips.lastLocation(tripId);
      _stale = false;
    } on ApiException {
      _stale = true;
    }

    if (_socket == null && _socketAttempts < _maxSocketAttempts) {
      _connectSocket();
    }
    notifyListeners();
  }

  void _connectSocket() {
    _socketAttempts++;

    _socket = _tracking.locations(tripId).listen(
      (point) {
        _vehicle = point;
        _stale = false;
        notifyListeners();
      },
      onError: (Object _) => _socket = null,
      onDone: () => _socket = null,
      cancelOnError: true,
    );
  }

  void _stopLive() {
    _socket?.cancel();
    _socket = null;
  }

  Future<void> refresh() async {
    if (_status == LoadStatus.ready) {
      await _tick();
    } else {
      await start();
    }
  }

  /// نام ایستگاه یک شناسه در مسیر این سفر.
  String? stationName(int? id) {
    if (id == null) return null;
    for (final info in _stops) {
      if (info.station.id == id) return info.station.name;
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopLive();
    super.dispose();
  }
}
