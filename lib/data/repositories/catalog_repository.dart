import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/station.dart';

/// داده‌های کم‌تغییر (سرویس‌ها، ایستگاه‌ها، مسیرها) که در حافظه cache می‌شوند.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Map<int, ServiceInfo>? _services;
  Map<int, Station>? _stations;
  final Map<int, List<RouteStop>> _routeStops = {};

  Future<Map<int, ServiceInfo>> services({bool refresh = false}) async {
    if (!refresh && _services != null) return _services!;

    final data = await _api.get('/services/', query: {'is_active': 'true'});
    _services = {
      for (final item in asMapList(data))
        ServiceInfo.fromJson(item).id: ServiceInfo.fromJson(item),
    };
    return _services!;
  }

  Future<Map<int, Station>> stations({bool refresh = false}) async {
    if (!refresh && _stations != null) return _stations!;

    final data = await _api.get('/stations/', query: {'is_active': 'true'});
    _stations = {
      for (final item in asMapList(data))
        Station.fromJson(item).id: Station.fromJson(item),
    };
    return _stations!;
  }

  Future<List<RouteStop>> routeStops(int routeId) async {
    final cached = _routeStops[routeId];
    if (cached != null) return cached;

    final data = await _api.get(
      '/route-stations/',
      query: {'route_id': '$routeId'},
    );
    final stops = [for (final item in asMapList(data)) RouteStop.fromJson(item)]
      ..sort((a, b) => a.order.compareTo(b.order));

    _routeStops[routeId] = stops;
    return stops;
  }

  /// ایستگاه‌های مرتب‌شده‌ی یک مسیر همراه با مشخصات ایستگاه.
  Future<List<RouteStationInfo>> routeStations(int routeId) async {
    final results = await Future.wait([routeStops(routeId), stations()]);
    final stops = results[0] as List<RouteStop>;
    final stationMap = results[1] as Map<int, Station>;

    return [
      for (final stop in stops)
        if (stationMap[stop.stationId] case final station?)
          RouteStationInfo(station: station, stop: stop),
    ];
  }
}
