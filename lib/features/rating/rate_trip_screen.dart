import 'package:flutter/material.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

/// امتیاز و نظر برای یک سفر انجام‌شده.
class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  final _message = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final studentId = StoresScope.read(context).session.studentId;
    if (_rating == 0 || studentId == null) return;

    final deps = DepsScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await deps.feedback.submit(
        tripId: widget.booking.trip.id,
        studentId: studentId,
        rating: _rating,
        message: _message.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, 'ممنون از بازخورد شما');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('امتیاز به سفر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.booking.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          Text(
            Fa.dayAndTime(widget.booking.trip.plannedDeparture),
            style: TextStyle(color: p.textMuted),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  iconSize: 40,
                  tooltip: '${Fa.digits(star)} ستاره',
                  onPressed: _busy ? null : () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: p.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            enabled: !_busy,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'نظر شما (اختیاری)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            SoftBanner(
              message: _error!,
              tone: Tone.danger,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_rating == 0 || _busy) ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('ثبت'),
          ),
        ],
      ),
    );
  }
}
