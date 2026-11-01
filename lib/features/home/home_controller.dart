import 'package:flutter/foundation.dart';

import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';

/// یک سفر قابل رزرو در لیست خانه.
class TripOption {
  const TripOption({required this.trip, required this.service});

  final Trip trip;
  final ServiceInfo service;
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

  LoadStatus get status => _status;
  String? get error => _error;
  bool get offline => _offline;
  List<TripOption> get options => _options;

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

      options.sort(
        (a, b) => a.trip.plannedDeparture.compareTo(b.trip.plannedDeparture),
      );

      _options = options;
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
}
