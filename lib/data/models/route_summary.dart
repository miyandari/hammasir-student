import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/l10n/l10n.dart';

/// خلاصه‌ی مسیر یک سرویس: مبدأ، مقصد و تعداد ایستگاه‌ها.
class RouteSummary {
  const RouteSummary({
    required this.from,
    required this.to,
    required this.stopCount,
  });

  final String from;
  final String to;
  final int stopCount;

  /// ایستگاه‌های بین راه (بدون مبدأ و مقصد).
  int get intermediate => stopCount > 2 ? stopCount - 2 : 0;

  /// «سرویس از پردیس به خوابگاه آوینی».
  String get title => L10n.t('service.from_to', {'from': from, 'to': to});

  static RouteSummary? of(List<RouteStationInfo> stops) {
    if (stops.length < 2) return null;
    return RouteSummary(
      from: stops.first.station.name,
      to: stops.last.station.name,
      stopCount: stops.length,
    );
  }
}
