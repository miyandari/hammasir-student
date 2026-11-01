import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/storage/token_store.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/user_profile.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStore tokens})
      : _api = api,
        _tokens = tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<bool> hasToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  /// ورود (فرم OAuth2) و ذخیره‌ی توکن.
  Future<void> login(String username, String password) async {
    final data = await _api.post(
      '/auth/login',
      auth: false,
      form: {'username': username.trim(), 'password': password},
    );

    final token = asString(asMap(data)?['access_token']);
    if (token.isEmpty) {
      throw const ApiException('پاسخ ورود نامعتبر است');
    }
    await _tokens.save(token);
  }

  Future<UserProfile> fetchProfile() async {
    final data = await _api.get('/users/me');
    final map = asMap(data);
    if (map == null) {
      throw const ApiException('اطلاعات حساب دریافت نشد');
    }
    return UserProfile.fromJson(map);
  }

  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _api.patch(
      '/users/me/password',
      body: {'current_password': current, 'new_password': next},
    );
  }

  Future<void> logout() => _tokens.clear();
}
