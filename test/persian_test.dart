import 'package:flutter_test/flutter_test.dart';

import 'package:hammasir_student/core/utils/persian.dart';

void main() {
  group('Fa', () {
    test('digits تبدیل ارقام لاتین به فارسی', () {
      expect(Fa.digits('12:30'), '۱۲:۳۰');
      expect(Fa.digits(null), '');
      expect(Fa.digits(7), '۷');
    });

    test('time با صفر پیشرو', () {
      expect(Fa.time(DateTime(2026, 1, 1, 7, 5)), '۰۷:۰۵');
    });

    test('dayLabel امروز/فردا/دیروز', () {
      final now = DateTime(2026, 5, 10, 12);
      expect(Fa.dayLabel(DateTime(2026, 5, 10, 8), now: now), 'امروز');
      expect(Fa.dayLabel(DateTime(2026, 5, 11, 8), now: now), 'فردا');
      expect(Fa.dayLabel(DateTime(2026, 5, 9, 8), now: now), 'دیروز');
    });

    test('duration', () {
      expect(Fa.duration(20), 'کمتر از ۱ دقیقه');
      expect(Fa.duration(240), '۴ دقیقه');
    });

    test('relative', () {
      final now = DateTime(2026, 5, 10, 12);
      expect(Fa.relative(now.subtract(const Duration(seconds: 5)), now: now),
          'همین الان');
      expect(Fa.relative(now.subtract(const Duration(minutes: 5)), now: now),
          '۵ دقیقه پیش');
      expect(Fa.relative(now.subtract(const Duration(hours: 3)), now: now),
          '۳ ساعت پیش');
    });
  });
}
