/// خطای یکدست برای همه‌ی درخواست‌های شبکه.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
  });

  /// پیام قابل نمایش به کاربر (فارسی).
  final String message;

  /// کد HTTP؛ برای خطاهای شبکه null است.
  final int? statusCode;

  /// true یعنی ارتباط با سرور برقرار نشد (قطع اینترنت یا timeout).
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
