import 'package:hammasir_student/core/storage/token_store.dart';

/// ذخیره‌گاه توکن در حافظه برای تست‌ها.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> save(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}
