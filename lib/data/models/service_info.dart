import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/l10n/l10n.dart';

/// سرویس (خط) مثل «خوابگاه ← دانشکده».
class ServiceInfo {
  const ServiceInfo({
    required this.id,
    required this.routeId,
    required this.name,
    required this.code,
    required this.genderRestriction,
  });

  final int id;
  final int routeId;
  final String name;
  final String code;

  /// mixed | male | female
  final String genderRestriction;

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: asInt(json['id']) ?? 0,
      routeId: asInt(json['route_id']) ?? 0,
      name: asString(json['name'], L10n.t('common.service')),
      code: asString(json['code']),
      genderRestriction: asString(json['gender_restriction'], 'mixed'),
    );
  }
}
