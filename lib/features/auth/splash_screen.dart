import 'package:flutter/material.dart';

import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/state/session_controller.dart';

/// هنگام باز شدن اپ؛ اگر ارتباط نبود دکمه‌ی تلاش دوباره دارد.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = session.startupError;

    return Scaffold(
      backgroundColor: p.brand,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هم‌مسیر',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: p.onBrand,
                ),
              ),
              const SizedBox(height: 24),
              if (error == null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: p.onBrand,
                  ),
                )
              else ...[
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.onBrand, height: 1.7),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: session.restore,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.onBrand,
                    foregroundColor: p.brand,
                    minimumSize: const Size(180, 50),
                  ),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
