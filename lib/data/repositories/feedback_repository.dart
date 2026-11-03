import 'package:hammasir_student/core/network/api_client.dart';

/// معیارهای بازخورد سفر. عنوان‌ها فارسی ثابت‌اند چون پنل مدیریت فارسی است.
class FeedbackTopic {
  FeedbackTopic._();

  static const String punctuality = 'punctuality';
  static const String driverBehavior = 'driver_behavior';
  static const String cleanliness = 'cleanliness';
  static const String safeDriving = 'safe_driving';
  static const String general = 'trip_rating';

  static const List<String> all = [
    punctuality,
    driverBehavior,
    cleanliness,
    safeDriving,
  ];

  static const Map<String, String> _titles = {
    punctuality: 'به‌موقع بودن',
    driverBehavior: 'رفتار راننده',
    cleanliness: 'تمیزی خودرو',
    safeDriving: 'رانندگی ایمن',
    general: 'امتیاز سفر',
  };

  static String title(String topic) => _titles[topic] ?? _titles[general]!;
}

class FeedbackRepository {
  FeedbackRepository(this._api);

  final ApiClient _api;

  /// به ازای هر معیار انتخاب‌شده یک بازخورد ثبت می‌شود (بک‌اند هر بازخورد را
  /// با یک نوع ذخیره می‌کند). اگر معیاری انتخاب نشده باشد، یک امتیاز کلی ثبت می‌شود.
  /// بک‌اند عنوان یا متن را اجباری می‌داند؛ عنوان همیشه ارسال می‌شود.
  Future<void> submit({
    required int tripId,
    required int studentId,
    required int rating,
    List<String> topics = const [],
    String? message,
  }) async {
    final text = message?.trim();
    final types = topics.isEmpty ? const [FeedbackTopic.general] : topics;

    for (final type in types) {
      await _api.post(
        '/feedbacks/',
        body: {
          'trip_id': tripId,
          'student_id': studentId,
          'rating': rating,
          'feedback_type': type,
          'title': FeedbackTopic.title(type),
          if (text != null && text.isNotEmpty) 'message': text,
        },
      );
    }
  }
}
