import 'package:flutter/foundation.dart';

import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/core/widgets/services_map.dart';
import 'package:hammasir_student/data/models/route_summary.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';

/// یک سفر قابل رزرو در لیست خانه.
class TripOption {
  const TripOption({required this.trip, required this.service, this.route});

  final Trip trip;
  final ServiceInfo service;

  /// مبدأ و مقصد سرویس؛ اگر مسیر بارگذاری نشد null است.
  final RouteSummary? route;

  /// عنوان قابل‌نمایش: «سرویس از X به Y» (یا نام ثبت‌شده در سرور).
  String get title => route?.title ?? service.name;
}

/// سفرهای امروز و دو روز بعد؛ فقط ۳ درخواست (یکی برای هر روز).
class HomeController extends ChangeNotifier with SafeNotifier {
  HomeController({
    required TripRepository trips,
    required CatalogRepository catalog,
    required String? Function() gender,
  })  : _trips = trips,
        _catalog = catalog,
        _gender = gender;

  static const int daysAhead = 3;

  final TripRepository _trips;
  final CatalogRepository _catalog;
  final String? Function() _gender;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  bool _offline = false;
  List<TripOption> _options = const [];
  List<MapPin> _pins = const [];

  LoadStatus get status => _status;
  String? get error => _error;
  bool get offline => _offline;
  List<TripOption> get options => _options;

  /// مارکرهای نقشه؛ برای هر سرویس نزدیک‌ترین سفر (خودرو اگر در مسیر باشد، وگرنه ایستگاه اول).
  List<MapPin> get pins => _pins;

  TripOption? optionForPin(int tripId) {
    for (final option in _options) {
      if (option.trip.id == tripId) return option;
    }
    return null;
  }

  Future<void> load() async {
    if (_options.isEmpty) {
      _status = LoadStatus.loading;
      notifyListeners();
    }

    try {
      final today = DateTime.now();
      final results = await Future.wait([
        for (var i = 0; i < daysAhead; i++)
          _trips.byDate(today.add(Duration(days: i))),
        _catalog.services(),
      ]);

      final services = results.last as Map<int, ServiceInfo>;
      final gender = _gender();

      final options = <TripOption>[];
      final seen = <int>{};

      for (var i = 0; i < daysAhead; i++) {
        for (final trip in results[i] as List<Trip>) {
          if (trip.isFinished || !seen.add(trip.id)) continue;

          final service = services[trip.serviceId];
          if (service == null) continue;
          if (!serviceAllowsGender(service.genderRestriction, gender)) continue;

          options.add(TripOption(trip: trip, service: service));
        }
      }

      final summaries = await _loadSummaries(
        {for (final o in options) o.service.routeId},
      );
      for (var i = 0; i < options.length; i++) {
        final o = options[i];
        options[i] = TripOption(
          trip: o.trip,
          service: o.service,
          route: summaries[o.service.routeId],
        );
      }

      options.sort(
        (a, b) => a.trip.plannedDeparture.compareTo(b.trip.plannedDeparture),
      );

      _options = options;
      _pins = await _buildPins(options);
      _status = LoadStatus.ready;
      _error = null;
      _offline = false;
    } on ApiException catch (e) {
      _error = e.message;
      if (_options.isEmpty) {
        _status = LoadStatus.error;
      } else {
        _status = LoadStatus.ready;
        _offline = true;
      }
    }

    notifyListeners();
  }

  Future<Map<int, RouteSummary>> _loadSummaries(Set<int> routeIds) async {
    final result = <int, RouteSummary>{};
    await Future.wait([
      for (final id in routeIds)
        () async {
          try {
            final summary = RouteSummary.of(await _catalog.routeStations(id));
            if (summary != null) result[id] = summary;
          } on ApiException {
            // نبودن خلاصه‌ی مسیر مانع نمایش سفر نیست.
          }
        }(),
    ]);
    return result;
  }

  Future<List<MapPin>> _buildPins(List<TripOption> options) async {
    final nearest = <int, TripOption>{};
    for (final option in options) {
      nearest.putIfAbsent(option.service.id, () => option);
    }

    final pins = await Future.wait([
      for (final option in nearest.values) _pinFor(option),
    ]);
    return [
      for (final pin in pins)
        if (pin != null) pin,
    ];
  }

  Future<MapPin?> _pinFor(TripOption option) async {
    try {
      if (option.trip.isLive) {
        final vehicle = await _trips.lastLocation(option.trip.id);
        if (vehicle != null) {
          return MapPin(id: option.trip.id, point: vehicle, live: true);
        }
      }

      final stops = await _catalog.routeStations(option.service.routeId);
      for (final info in stops) {
        final point = info.station.point;
        if (point != null) {
          return MapPin(id: option.trip.id, point: point, live: false);
        }
      }
    } on ApiException {
      // مارکر اختیاری است؛ نبودنش مانع بقیه‌ی صفحه نیست.
    }
    return null;
  }
}
