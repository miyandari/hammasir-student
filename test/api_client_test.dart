import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';

import 'helpers.dart';

http.Response _json(Object body, [int status = 200]) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  test('توکن را در هدر می‌فرستد', () async {
    String? auth;
    final api = ApiClient(
      tokens: MemoryTokenStore('abc'),
      client: MockClient((request) async {
        auth = request.headers['Authorization'];
        return _json({'ok': true});
      }),
    );

    final data = await api.get('/ping/');
    expect(auth, 'Bearer abc');
    expect(data, {'ok': true});
  });

  test('بدون توکن درخواست نمی‌فرستد', () async {
    var called = false;
    final api = ApiClient(
      tokens: MemoryTokenStore(),
      client: MockClient((request) async {
        called = true;
        return _json({});
      }),
    );

    await expectLater(
      api.get('/ping/'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)),
    );
    expect(called, isFalse);
  });

  test('401 رویداد onUnauthorized را صدا می‌زند', () async {
    var expired = 0;
    final api = ApiClient(
      tokens: MemoryTokenStore('abc'),
      client: MockClient((_) async => _json({'detail': 'x'}, 401)),
    )..onUnauthorized = () => expired++;

    await expectLater(api.get('/ping/'), throwsA(isA<ApiException>()));
    expect(expired, 1);
  });

  test('پیام detail فارسی استخراج می‌شود', () async {
    final api = ApiClient(
      tokens: MemoryTokenStore('abc'),
      client: MockClient(
        (_) async => _json({'detail': 'ظرفیت پر است'}, 400),
      ),
    );

    await expectLater(
      api.post('/reservations/', body: {'a': 1}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'ظرفیت پر است')
            .having((e) => e.statusCode, 'status', 400),
      ),
    );
  });

  test('422 و 500 پیام عمومی می‌دهند', () async {
    ApiClient make(int status) => ApiClient(
          tokens: MemoryTokenStore('abc'),
          client: MockClient(
            (_) async => _json({
              'detail': [
                {'msg': 'field required'},
              ],
            }, status),
          ),
        );

    await expectLater(
      make(422).get('/x/'),
      throwsA(isA<ApiException>().having(
        (e) => e.message,
        'message',
        'اطلاعات واردشده معتبر نیست.',
      )),
    );
    await expectLater(
      make(500).get('/x/'),
      throwsA(isA<ApiException>().having(
        (e) => e.message.contains('خطای سرور'),
        'server message',
        true,
      )),
    );
  });

  test('خطای شبکه به ApiException با isNetwork تبدیل می‌شود', () async {
    final api = ApiClient(
      tokens: MemoryTokenStore('abc'),
      client: MockClient((_) async => throw http.ClientException('down')),
    );

    await expectLater(
      api.get('/x/'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'network', true)),
    );
  });

  test('ورود با فرم و بدون توکن', () async {
    http.BaseRequest? seen;
    final api = ApiClient(
      tokens: MemoryTokenStore(),
      client: MockClient((request) async {
        seen = request;
        return _json({'access_token': 't', 'token_type': 'bearer'});
      }),
    );

    await api.post('/auth/login', auth: false, form: {'username': 'a', 'password': 'b'});
    expect(seen!.method, 'POST');
    expect(seen!.headers.containsKey('Authorization'), isFalse);
    expect((seen! as http.Request).body, contains('username=a'));
  });
}
