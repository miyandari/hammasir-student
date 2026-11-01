import 'package:flutter/widgets.dart';

import 'package:hammasir_student/state/theme_controller.dart';

/// دسترسی صفحه‌ها به کنترلر تم (فقط برای صفحه‌ی پروفایل).
class ThemeScope extends InheritedWidget {
  const ThemeScope({super.key, required this.controller, required super.child});

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope در درخت ویجت پیدا نشد');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      controller != oldWidget.controller;
}
