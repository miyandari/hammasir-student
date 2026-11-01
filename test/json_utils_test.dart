import 'package:flutter_test/flutter_test.dart';

import 'package:hammasir_student/core/utils/json_utils.dart';

void main() {
  test('asInt و asDouble با ورودی‌های مختلف', () {
    expect(asInt(5), 5);
    expect(asInt('7'), 7);
    expect(asInt(3.9), 3);
    expect(asInt(null), isNull);
    expect(asInt('x'), isNull);
    expect(asDouble('1.5'), 1.5);
    expect(asDouble(2), 2.0);
  });

  test('asString و asNullableString', () {
    expect(asString(null, 'پیش‌فرض'), 'پیش‌فرض');
    expect(asString(12), '12');
    expect(asNullableString('  '), isNull);
    expect(asNullableString('الف'), 'الف');
  });

  test('asDate زمان UTC را به محلی برمی‌گرداند', () {
    final date = asDate('2026-05-10T04:00:00Z');
    expect(date, isNotNull);
    expect(date!.isUtc, isFalse);
    expect(asDate('نامعتبر'), isNull);
    expect(asDate(null), isNull);
  });

  test('asMap و asMapList', () {
    expect(asMap({'a': 1}), {'a': 1});
    expect(asMap(<dynamic, dynamic>{'a': 1}), {'a': 1});
    expect(asMap('x'), isNull);
    expect(asMapList([{'a': 1}, 5, {'b': 2}]).length, 2);
    expect(asMapList(null), isEmpty);
  });
}
