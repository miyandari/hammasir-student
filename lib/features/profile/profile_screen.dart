import 'package:flutter/material.dart';

import 'package:hammasir_student/app/theme_scope.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/choice_tile.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/features/profile/change_password_screen.dart';
import 'package:hammasir_student/features/reservations/reservations_screen.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/state/session_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});

  final SessionController session;

  Future<void> _logout(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'خروج از حساب',
      message: 'از حساب خود خارج می‌شوید؟',
      confirmLabel: 'خروج',
    );
    if (!ok) return;
    await session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([session, theme]),
      builder: (context, _) {
        final profile = session.profile;
        final student = session.student;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const PageHeader(title: 'من'),
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: p.brandSoft,
                    child: Icon(Icons.person, color: p.brand, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName ?? '',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        if (student != null)
                          Text(
                            'شماره دانشجویی: ${Fa.digits(student.studentNumber)}',
                            style: TextStyle(color: p.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (student != null) ...[
              const SectionTitle('وضعیت رزرو'),
              if (student.isBlocked)
                SoftBanner(
                  message: student.blockedUntil == null
                      ? 'رزرو شما مسدود است.'
                      : 'رزرو شما تا ${Fa.dayAndTime(student.blockedUntil!)} '
                          'مسدود است.',
                  tone: Tone.danger,
                  icon: Icons.block,
                )
              else
                const SoftBanner(
                  message: 'رزرو شما فعال است.',
                  tone: Tone.success,
                  icon: Icons.check_circle_outline,
                ),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    _Stat(
                      label: 'غیبت بدون لغو',
                      value: Fa.digits(student.noShowCount),
                    ),
                    _Stat(
                      label: 'امتیاز منفی',
                      value: Fa.digits(student.negativeScore),
                    ),
                  ],
                ),
              ),
            ],
            const SectionTitle('نمایش'),
            for (final option in const [
              (ThemeMode.system, 'مطابق دستگاه'),
              (ThemeMode.light, 'روشن'),
              (ThemeMode.dark, 'تیره'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceTile(
                  title: option.$2,
                  selected: theme.mode == option.$1,
                  onTap: () => theme.setMode(option.$1),
                ),
              ),
            const SectionTitle('حساب'),
            _LinkTile(
              icon: Icons.history,
              title: 'تاریخچه سفرها',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TripHistoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.lock_outline,
              title: 'تغییر رمز عبور',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.logout,
              title: 'خروج از حساب',
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
          if (!danger) Icon(Icons.chevron_left, color: p.textMuted),
        ],
      ),
    );
  }
}
