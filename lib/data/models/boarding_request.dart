import 'package:hammasir_student/core/utils/json_utils.dart';

class BoardingRequest {
  const BoardingRequest({
    required this.id,
    required this.tripId,
    required this.status,
    this.rejectionReason,
  });

  final int id;
  final int tripId;

  /// pending | approved | rejected | cancelled
  final String status;
  final String? rejectionReason;

  factory BoardingRequest.fromJson(Map<String, dynamic> json) {
    return BoardingRequest(
      id: asInt(json['id']) ?? 0,
      tripId: asInt(json['trip_id']) ?? 0,
      status: asString(json['status']),
      rejectionReason: asNullableString(json['rejection_reason']),
    );
  }
}
