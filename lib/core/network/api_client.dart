import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hammasir_student/core/config/app_config.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/storage/token_store.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';

/// تنها نقطه‌ی ارتباط با Backend.
///
/// - توکن را خودکار اضافه می‌کند
/// - timeout دارد
/// - همه‌ی خطاها را به [ApiException] فارسی تبدیل می‌کند
/// - در 401 رویداد [onUnauthorized] را صدا می‌زند
///
/// مسیرها باید با «/» پایانی نوشته شوند (مثل `/trips/`)، چون FastAPI
/// در غیر این صورت ریدایرکت می‌کند و POST دنبال نمی‌شود.
class ApiClient {
  ApiClient({required TokenStore tokens, http.Client? client})
      : _tokens = tokens,
        _client = client ?? http.Client();

  final TokenStore _tokens;
  final http.Client _client;

  /// وقتی توکن منقضی یا نامعتبر باشد صدا زده می‌شود.
  void Function()? onUnauthorized;

  Uri _uri(String path, Map<String, String?>? query) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) params[key] = value;
    });

    return Uri.parse(AppConfig.apiBaseUrl).replace(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) {
    return _send(
      (headers) => _client.get(_uri(path, query), headers: headers),
    );
  }

  /// [form] برای ورود (application/x-www-form-urlencoded) و [body] برای JSON.
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? form,
    bool auth = true,
  }) {
    return _send(
      auth: auth,
      (headers) => _client.post(
        _uri(path, null),
        headers: {
          ...headers,
          if (body != null) 'Content-Type': 'application/json',
        },
        body: form ?? (body == null ? null : jsonEncode(body)),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send(
      (headers) => _client.patch(
        _uri(path, null),
        headers: {
          ...headers,
          if (body != null) 'Content-Type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) call, {
    bool auth = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (auth) {
      final token = await _tokens.read();

      if (token == null || token.isEmpty) {
        throw const ApiException(
          'ابتدا وارد حساب خود شوید',
          statusCode: 401,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;

    try {
      response = await call(headers).timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'پاسخ سرور دیر شد؛ اینترنت خود را بررسی کنید',
        isNetwork: true,
      );
    } catch (_) {
      throw const ApiException(
        'ارتباط با سرور برقرار نشد',
        isNetwork: true,
      );
    }

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401 && auth) {
      onUnauthorized?.call();
      throw const ApiException(
        'نشست شما منقضی شده است',
        statusCode: 401,
      );
    }

    throw ApiException(
      _errorMessage(decoded, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(dynamic body, int statusCode) {
    final detail = asMap(body)?['detail'];

    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    if (statusCode == 422) {
      return 'اطلاعات واردشده معتبر نیست';
    }

    if (statusCode >= 500) {
      return 'خطای سرور؛ کمی بعد دوباره تلاش کنید';
    }

    return 'درخواست ناموفق بود';
  }

  void close() => _client.close();
}
