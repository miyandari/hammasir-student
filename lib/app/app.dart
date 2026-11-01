import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/shell.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/app/theme_scope.dart';
import 'package:hammasir_student/core/theme/app_theme.dart';
import 'package:hammasir_student/features/auth/login_screen.dart';
import 'package:hammasir_student/features/auth/splash_screen.dart';
import 'package:hammasir_student/state/session_controller.dart';
import 'package:hammasir_student/state/theme_controller.dart';

/// ریشه‌ی برنامه: وابستگی‌ها، نشست، تم و ذخیره‌گاه‌های مشترک.
class HammasirApp extends StatefulWidget {
  const HammasirApp({super.key, this.deps});

  /// برای تست می‌توان Deps ساختگی داد.
  final Deps? deps;

  @override
  State<HammasirApp> createState() => _HammasirAppState();
}

class _HammasirAppState extends State<HammasirApp> {
  late final Deps _deps = widget.deps ?? Deps();
  late final SessionController _session = SessionController(
    auth: _deps.auth,
    students: _deps.students,
  );
  late final ThemeController _theme = ThemeController(_deps.settings);

  Stores? _stores;

  @override
  void initState() {
    super.initState();
    _deps.api.onUnauthorized = _session.expire;
    _session.addListener(_syncStores);
    _theme.load();
    _session.restore();
  }

  /// با هر ورود، ذخیره‌گاه‌های تازه؛ با هر خروج، دور ریختن آن‌ها.
  void _syncStores() {
    final loggedIn = _session.status == SessionStatus.loggedIn;

    if (loggedIn && _stores == null) {
      setState(() => _stores = Stores(_deps, session: _session));
    } else if (!loggedIn && _stores != null) {
      final old = _stores!;
      setState(() => _stores = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _session.removeListener(_syncStores);
    _session.dispose();
    _theme.dispose();
    _stores?.dispose();
    if (widget.deps == null) _deps.dispose();
    super.dispose();
  }

  Widget _home() {
    switch (_session.status) {
      case SessionStatus.starting:
        return SplashScreen(session: _session);
      case SessionStatus.loggedOut:
        return LoginScreen(session: _session);
      case SessionStatus.loggedIn:
        // ذخیره‌گاه‌ها در همین فریم ساخته می‌شوند؛ این گارد فقط محافظ است.
        if (_stores == null) return SplashScreen(session: _session);
        return Shell(session: _session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DepsScope(
      deps: _deps,
      child: ListenableBuilder(
        listenable: Listenable.merge([_session, _theme]),
        builder: (context, _) {
          final app = MaterialApp(
            title: 'هم‌مسیر',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _theme.mode,
            locale: const Locale('fa'),
            supportedLocales: const [Locale('fa')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _home(),
          );

          final themed = ThemeScope(controller: _theme, child: app);
          final stores = _stores;
          if (stores == null) return themed;
          return StoresScope(stores: stores, child: themed);
        },
      ),
    );
  }
}
