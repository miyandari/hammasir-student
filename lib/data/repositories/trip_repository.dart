import 'package:latlong2/latlong.dart';

import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/live_eta.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/models/trip_availability.dart';

class TripRepository {
  TripRepository(this._api);

  final ApiClient _api;

  static String _dateParam(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<List<Trip>> byDate(DateTime date) async {
    final data = await _api.get(
      '/trips/',
      query: {'trip_date': _dateParam(date)},
    );
    return [for (final item in asMapList(data)) Trip.fromJson(item)];
  }

  Future<Trip> byId(int id) async {
    final data = await _api.get('/trips/$id');
    final map = asMap(data);
    if (map == null) throw const ApiException('سفر پیدا نشد');
    return Trip.fromJson(map);
  }

  /// ظرفیت باقی‌مانده؛ اگر بک‌اند endpoint را ندارد null می‌دهد.
  Future<TripAvailability?> availability(int tripId) async {
    try {
      final data = await _api.get('/trips/$tripId/availability');
      final map = asMap(data);
      return map == null ? null : TripAvailability.fromJson(map);
    } on ApiException catch (e) {
      if (e.isNetwork || e.isUnauthorized) rethrow;
      return null;
    }
  }

  /// ETA و موقعیت خودرو. وقتی هنوز GPS نیامده بک‌اند 400/404 می‌دهد؛ آن را null می‌گیریم.
  Future<LiveEta?> eta(int tripId) async {
    try {
      final data = await _api.get('/trips/$tripId/eta/next-station');
      final map = asMap(data);
      return map == null ? null : LiveEta.fromJson(map);
    } on ApiException catch (e) {
      if (e.isNetwork || e.isUnauthorized) rethrow;
      return null;
    }
  }

  Future<LatLng?> lastLocation(int tripId) async {
    try {
      final data = await _api.get('/vehicle-locations/latest/$tripId');
      final map = asMap(data);
      final lat = asDouble(map?['latitude']);
      final lng = asDouble(map?['longitude']);
      return (lat == null || lng == null) ? null : LatLng(lat, lng);
    } on ApiException catch (e) {
      if (e.isNetwork || e.isUnauthorized) rethrow;
      return null;
    }
  }
}
