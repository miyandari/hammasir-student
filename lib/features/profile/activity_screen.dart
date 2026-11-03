import 'package:flutter/material.dart';

import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/state/activity_store.dart';
import 'package:hammasir_student/l10n/l10n.dart';

/// فعالیت‌های من: جدیدترین‌ها در صدر.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static IconData _icon(String type) {
    switch (type) {
      case ActivityType.reserve:
        return Icons.event_available_rounded;
      case ActivityType.waitlist:
        return Icons.hourglass_bottom_rounded;
      case ActivityType.cancel:
        return Icons.event_busy_rounded;
      case ActivityType.rate:
        return Icons.star_rounded;
      case ActivityType.password:
        return Icons.lock_reset_rounded;
      case ActivityType.avatar:
      case ActivityType.avatarRemoved:
        return Icons.account_circle_outlined;
      default:
        return Icons.fingerprint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = StoresScope.of(context).activity;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('activity.title'))),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.entries;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.t('activity.empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, height: 1.8),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final e = entries[index];
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon(e.type), color: p.brand, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('act.${e.type}'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          if (e.detail != null)
                            Text(
                              e.detail!,
                              style: TextStyle(
                                fontSize: 13,
                                color: p.textMuted,
                              ),
                            ),
                          Text(
                            '${Fa.dayAndTime(e.time)} · ${Fa.relative(e.time)}',
                            style: TextStyle(fontSize: 12, color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
