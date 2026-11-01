import 'package:hammasir_student/core/network/api_client.dart';

class FeedbackRepository {
  FeedbackRepository(this._api);

  final ApiClient _api;

  Future<void> submit({
    required int tripId,
    required int studentId,
    required int rating,
    String? message,
  }) async {
    final text = message?.trim();
    await _api.post(
      '/feedbacks/',
      body: {
        'trip_id': tripId,
        'student_id': studentId,
        'rating': rating,
        'feedback_type': 'trip_rating',
        if (text != null && text.isNotEmpty) 'message': text,
      },
    );
  }
}
