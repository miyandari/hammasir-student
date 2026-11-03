import 'package:flutter/widgets.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/state/activity_store.dart';
import 'package:hammasir_student/state/avatar_controller.dart';
import 'package:hammasir_student/state/my_trips_store.dart';
import 'package:hammasir_student/state/session_controller.dart';
import 'package:hammasir_student/state/notifications_store.dart';

/// داده‌های مشترک بین صفحه‌ها؛ برای هر ورود جدید ساخته و با خروج دور ریخته می‌شود،
/// پس اطلاعات یک دانشجو هرگز برای دانشجوی بعدی نمی‌ماند.
class Stores {
  Stores(Deps deps, {required this.session})
      : myTrips = MyTripsStore(
          reservations: deps.reservations,
          trips: deps.trips,
          catalog: deps.catalog,
        ),
        notifications = NotificationsStore(deps.notifications),
        avatar = AvatarController(deps.settings),
        activity = ActivityStore(deps.settings);

  final SessionController session;
  final MyTripsStore myTrips;
  final NotificationsStore notifications;
  final AvatarController avatar;
  final ActivityStore activity;

  void dispose() {
    myTrips.dispose();
    notifications.dispose();
    avatar.dispose();
    activity.dispose();
  }
}

class StoresScope extends InheritedWidget {
  const StoresScope({super.key, required this.stores, required super.child});

  final Stores stores;

  /// برای initState (بدون ثبت وابستگی).
  static Stores read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoresScope>();
    assert(scope != null, 'StoresScope در درخت ویجت پیدا نشد');
    return scope!.stores;
  }

  static Stores of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoresScope>();
    assert(scope != null, 'StoresScope در درخت ویجت پیدا نشد');
    return scope!.stores;
  }

  @override
  bool updateShouldNotify(StoresScope oldWidget) => stores != oldWidget.stores;
}
