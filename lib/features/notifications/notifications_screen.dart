import 'package:flutter/material.dart';

import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/data/models/notification_item.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/trip/trip_screen.dart';
import 'package:hammasir_student/state/notifications_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoresScope.read(context).notifications;
    _store.load();
  }

  void _open(NotificationItem item) {
    _store.markRead(item);

    final tripId = item.tripId;
    if (tripId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Column(
          children: [
            PageHeader(
              title: 'اعلان‌ها',
              trailing: _store.unread > 0
                  ? TextButton(
                      onPressed: _store.markAllRead,
                      child: const Text('خواندن همه'),
                    )
                  : null,
            ),
            Expanded(child: _body(context)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (_store.status == LoadStatus.loading && _store.items.isEmpty) {
      return const CenteredLoader();
    }

    if (_store.status == LoadStatus.error && _store.items.isEmpty) {
      return ErrorState(
        message: _store.error ?? 'خطا در دریافت اعلان‌ها',
        onRetry: _store.load,
      );
    }

    return RefreshIndicator(
      onRefresh: _store.load,
      child: _store.items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              message: 'اعلانی ندارید.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _store.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _store.items[index];
                return _NotificationTile(item: item, onTap: () => _open(item));
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      color: item.isRead ? p.surface : p.brandSoft,
      borderColor: item.isRead ? p.border : p.brandSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 10),
            child: Icon(
              Icons.circle,
              size: 10,
              color: item.isRead ? Colors.transparent : p.brand,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(color: p.text, height: 1.7, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  Fa.relative(item.createdAt),
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
