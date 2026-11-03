import 'package:flutter/material.dart';

import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/core/widgets/user_avatar.dart';
import 'package:hammasir_student/features/profile/about_screen.dart';
import 'package:hammasir_student/features/profile/activity_screen.dart';
import 'package:hammasir_student/features/profile/contact_screen.dart';
import 'package:hammasir_student/features/profile/settings_screen.dart';
import 'package:hammasir_student/features/reservations/reservations_screen.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/activity_store.dart';
import 'package:hammasir_student/state/session_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});

  final SessionController session;

  Future<void> _logout(BuildContext context) async {
    final ok = await confirm(
      context,
      title: context.t('profile.logout_title'),
      message: context.t('profile.logout_message'),
      confirmLabel: context.t('profile.logout'),
      icon: Icons.logout_rounded,
      tone: Tone.danger,
      destructive: true,
    );
    if (!ok) return;
    await session.logout();
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final avatar = StoresScope.read(context).avatar;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.t('profile.photo_choose')),
              onTap: () => Navigator.of(sheet).pop('pick'),
            ),
            if (avatar.path != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: context.palette.danger,
                ),
                title: Text(context.t('profile.photo_remove')),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );

    final activity = StoresScope.read(context).activity;
    if (action == 'pick') {
      if (await avatar.pickFromGallery()) {
        activity.record(ActivityType.avatar);
      }
    } else if (action == 'remove') {
      await avatar.remove();
      activity.record(ActivityType.avatarRemoved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final avatar = StoresScope.of(context).avatar;

    return ListenableBuilder(
      listenable: Listenable.merge([session, avatar]),
      builder: (context, _) {
        final profile = session.profile;
        final student = session.student;
        final name = profile?.fullName ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            PageHeader(
              title: context.t('profile.title'),
              trailing: IconButton(
                tooltip: context.t('settings.title'),
                icon: Icon(Icons.settings_outlined, color: p.text),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ),
            AppCard(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _pickPhoto(context),
                    child: Stack(
                      children: [
                        UserAvatar(name: name, imagePath: avatar.path, size: 64),
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: p.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.border),
                            ),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 14,
                              color: p.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        if (student != null)
                          Text(
                            context.t('profile.student_number', {
                              'n': Fa.digits(student.studentNumber),
                            }),
                            style: TextStyle(color: p.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (student != null) ...[
              SectionTitle(context.t('profile.status')),
              if (student.isBlocked)
                SoftBanner(
                  message: student.blockedUntil == null
                      ? context.t('profile.blocked')
                      : context.t('profile.blocked_until', {
                          'when': Fa.dayAndTime(student.blockedUntil!),
                        }),
                  tone: Tone.danger,
                  icon: Icons.block,
                )
              else
                SoftBanner(
                  message: context.t('profile.active'),
                  tone: Tone.success,
                  icon: Icons.check_circle_outline,
                ),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    _Stat(
                      label: context.t('profile.no_shows'),
                      value: Fa.digits(student.noShowCount),
                    ),
                    _Stat(
                      label: context.t('profile.negative_score'),
                      value: Fa.digits(student.negativeScore),
                    ),
                  ],
                ),
              ),
            ],
            SectionTitle(context.t('profile.account')),
            _LinkTile(
              icon: Icons.history,
              title: context.t('res.history_title'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TripHistoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.timeline_rounded,
              title: context.t('profile.activity'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ActivityScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.settings_outlined,
              title: context.t('settings.title'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.info_outline_rounded,
              title: context.t('profile.about'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.support_agent_rounded,
              title: context.t('profile.contact'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.logout,
              title: context.t('profile.logout'),
              danger: true,
              onTap: () => _logout(context),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.danger : p.text;

    return AppCard(
      onTap: onTap,
      borderColor: danger ? p.dangerBorder : null,
      child: Row(
        children: [
          Icon(icon, color: danger ? p.danger : p.brand),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(color: color))),
          if (!danger) Icon(Icons.chevron_right, color: p.textMuted),
        ],
      ),
    );
  }
}
