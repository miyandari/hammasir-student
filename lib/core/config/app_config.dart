/// تنظیمات ثابت برنامه.
///
/// آدرس سرور هنگام اجرا تعیین می‌شود، نه داخل کد:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class AppConfig {
  AppConfig._();

  /// آدرس Backend.
  /// - امولاتور اندروید:  http://10.0.2.2:8000
  /// - گوشی واقعی با adb reverse:  http://127.0.0.1:8000
  /// - سرور واقعی: حتماً https
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// حداکثر زمان انتظار برای پاسخ هر درخواست.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// فاصله بررسی دوره‌ای وضعیت سفر وقتی اتصال زنده در دسترس نیست.
  static const Duration livePollInterval = Duration(seconds: 15);

  /// تایل نقشه. برای انتشار عمومی از یک سرویس تایل مناسب خودتان استفاده کنید
  /// (سیاست استفاده OpenStreetMap برای ترافیک بالا مناسب نیست).
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// شناسه بسته برای درخواست‌های تایل نقشه.
  static const String userAgentPackage = 'ir.hammasir.student';
}
