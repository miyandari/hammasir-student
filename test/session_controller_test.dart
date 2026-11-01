import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/data/repositories/auth_repository.dart';
import 'package:hammasir_student/data/repositories/student_repository.dart';
import 'package:hammasir_student/state/session_controller.dart';

import 'helpers.dart';

http.Response _json(Object body, [int status = 200]) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

SessionController _session({
  required String role,
  required MemoryTokenStore tokens,
  bool studentEndpoint = false,
}) {
  final api = ApiClient(
    tokens: tokens,
    client: MockClient((request) async {
      final path = request.url.path;
      if (path == '/auth/login') {
        return _json({'access_token': 'tok', 'token_type': 'bearer'});
      }
      if (path == '/users/me') {
        return _json({
          'id': 1,
          'username': 'std',
          'first_name': 'علی',
          'last_name': 'رضایی',
          'role': role,
          'student_id': role == 'student' ? 9 : null,
          'university_id': 1,
        });
      }
      if (path == '/students/me') {
        return studentEndpoint
            ? _json({
                'id': 9,
                'student_number': '4001',
                'gender': 'male',
                'no_show_count': 1,
                'negative_score': 2,
                'is_blocked': false,
              })
            : _json({'detail': 'Not Found'}, 404);
      }
      return _json({}, 404);
    }),
  );

  return SessionController(
    auth: AuthRepository(api: api, tokens: tokens),
    students: StudentRepository(api),
  );
}

void main() {
  test('ورود دانشجو موفق (بدون endpoint جدید بک‌اند)', () async {
    final tokens = MemoryTokenStore();
    final session = _session(role: 'student', tokens: tokens);

    final error = await session.login('std', 'pass');

    expect(error, isNull);
    expect(session.status, SessionStatus.loggedIn);
    expect(session.studentId, 9);
    expect(session.student, isNull);
    expect(tokens.token, 'tok');
    expect(session.profile!.fullName, 'علی رضایی');
  });

  test('وضعیت دانشجو وقتی endpoint جدید وجود دارد', () async {
    final session = _session(
      role: 'student',
      tokens: MemoryTokenStore(),
      studentEndpoint: true,
    );

    await session.login('std', 'pass');

    expect(session.student?.noShowCount, 1);
    expect(session.gender, 'male');
  });

  test('حساب غیر دانشجو پذیرفته نمی‌شود و توکن پاک می‌شود', () async {
    final tokens = MemoryTokenStore();
    final session = _session(role: 'driver', tokens: tokens);

    final error = await session.login('drv', 'pass');

    expect(error, contains('دانشجو'));
    expect(session.status, SessionStatus.loggedOut);
    expect(tokens.token, isNull);
  });

  test('restore بدون توکن به صفحه ورود می‌رود', () async {
    final session = _session(role: 'student', tokens: MemoryTokenStore());
    await session.restore();
    expect(session.status, SessionStatus.loggedOut);
  });

  test('restore با توکن معتبر', () async {
    final session = _session(role: 'student', tokens: MemoryTokenStore('t'));
    await session.restore();
    expect(session.status, SessionStatus.loggedIn);
  });

  test('logout و expire', () async {
    final tokens = MemoryTokenStore();
    final session = _session(role: 'student', tokens: tokens);
    await session.login('std', 'pass');

    session.expire();
    expect(session.status, SessionStatus.loggedOut);
    expect(session.notice, isNotNull);
    expect(session.profile, isNull);
  });
}
