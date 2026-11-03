import 'package:flutter/material.dart';

import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/features/home/home_screen.dart';
import 'package:hammasir_student/features/notifications/notifications_screen.dart';
import 'package:hammasir_student/features/profile/profile_screen.dart';
import 'package:hammasir_student/features/reservations/reservations_screen.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/session_controller.dart';

/// قاب اصلی با چهار تب پایین.
class Shell extends StatefulWidget {
  const Shell({super.key, required this.session});

  final SessionController session;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _index = 0;
  late final Stores _stores;

  @override
  void initState() {
    super.initState();
    _stores = StoresScope.read(context);
    WidgetsBinding.instance.addObserver(this);
    _stores.notifications.startPolling();
    _stores.myTrips.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// با برگشت به اپ، داده‌ها تازه می‌شوند و در پس‌زمینه polling متوقف است.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stores.notifications.startPolling();
      _stores.myTrips.load();
    } else if (state == AppLifecycleState.paused) {
      _stores.notifications.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(session: widget.session),
            const ReservationsScreen(),
            const NotificationsScreen(),
            ProfileScreen(session: widget.session),
          ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _stores.notifications,
        builder: (context, _) {
          final unread = _stores.notifications.unread;

          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: context.t('nav.home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: context.t('nav.reservations'),
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(Fa.digits(unread)),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(Fa.digits(unread)),
                  child: const Icon(Icons.notifications),
                ),
                label: context.t('nav.notifications'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: context.t('nav.account'),
              ),
            ],
          );
        },
      ),
    );
  }
}
