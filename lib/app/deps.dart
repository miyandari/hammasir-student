import 'package:flutter/widgets.dart';

import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/security/biometric_service.dart';
import 'package:hammasir_student/core/storage/settings_store.dart';
import 'package:hammasir_student/core/storage/token_store.dart';
import 'package:hammasir_student/data/repositories/auth_repository.dart';
import 'package:hammasir_student/data/repositories/catalog_repository.dart';
import 'package:hammasir_student/data/repositories/feedback_repository.dart';
import 'package:hammasir_student/data/repositories/notification_repository.dart';
import 'package:hammasir_student/data/repositories/reservation_repository.dart';
import 'package:hammasir_student/data/repositories/routing_repository.dart';
import 'package:hammasir_student/data/repositories/student_repository.dart';
import 'package:hammasir_student/data/repositories/tracking_repository.dart';
import 'package:hammasir_student/data/repositories/trip_repository.dart';

/// همه‌ی وابستگی‌های شبکه/داده؛ یک بار ساخته می‌شود و با InheritedWidget در دسترس است.
class Deps {
  Deps({
    TokenStore? tokens,
    ApiClient? api,
    SettingsStore? settings,
    BiometricService? biometric,
  })  : tokens = tokens ?? SecureTokenStore(),
        settings = settings ?? SettingsStore(),
        biometric = biometric ?? BiometricService() {
    this.api = api ?? ApiClient(tokens: this.tokens);
    auth = AuthRepository(api: this.api, tokens: this.tokens);
    students = StudentRepository(this.api);
    catalog = CatalogRepository(this.api);
    trips = TripRepository(this.api);
    reservations = ReservationRepository(this.api);
    notifications = NotificationRepository(this.api);
    feedback = FeedbackRepository(this.api);
    tracking = TrackingRepository(this.tokens);
    routing = RoutingRepository();
  }

  final TokenStore tokens;
  final SettingsStore settings;
  final BiometricService biometric;
  late final ApiClient api;
  late final AuthRepository auth;
  late final StudentRepository students;
  late final CatalogRepository catalog;
  late final TripRepository trips;
  late final ReservationRepository reservations;
  late final NotificationRepository notifications;
  late final FeedbackRepository feedback;
  late final TrackingRepository tracking;
  late final RoutingRepository routing;

  void dispose() {
    api.close();
    routing.close();
  }
}

class DepsScope extends InheritedWidget {
  const DepsScope({super.key, required this.deps, required super.child});

  final Deps deps;

  /// برای initState (بدون ثبت وابستگی).
  static Deps read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DepsScope>();
    assert(scope != null, 'DepsScope در درخت ویجت پیدا نشد');
    return scope!.deps;
  }

  static Deps of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DepsScope>();
    assert(scope != null, 'DepsScope در درخت ویجت پیدا نشد');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(DepsScope oldWidget) => deps != oldWidget.deps;
}
