import 'package:flutter/material.dart';

import 'package:hammasir_student/state/activity_store.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/repositories/feedback_repository.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

/// امتیاز و بازخورد برای یک سفر انجام‌شده (مطابق طرح تأییدشده).
class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  static const Map<String, String> _topicKeys = {
    FeedbackTopic.punctuality: 'rate.topic_punctuality',
    FeedbackTopic.driverBehavior: 'rate.topic_driver',
    FeedbackTopic.cleanliness: 'rate.topic_clean',
    FeedbackTopic.safeDriving: 'rate.topic_safe',
  };

  final _message = TextEditingController();
  final Set<String> _topics = {};
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
        topics: [
          for (final topic in FeedbackTopic.all)
            if (_topics.contains(topic)) topic,
        ],
        message: _message.text,
      );
      if (!mounted) return;
      StoresScope.read(context).activity.record(
        ActivityType.rate,
        detail: widget.booking.title,
      );
      Navigator.of(context).pop();
      showMessage(context, context.t('rate.thanks'), tone: Tone.success);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 34, color: p.success),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.t('rate.trip_done'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.booking.title} · '
            '${Fa.dayAndTime(widget.booking.trip.plannedDeparture)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted),
          ),
          const SizedBox(height: 20),
          AppCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              children: [
                Text(
                  context.t('rate.how_was'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        iconSize: 38,
                        tooltip: context.t('rate.stars', {'n': Fa.digits(star)}),
                        onPressed:
                            _busy ? null : () => setState(() => _rating = star),
                        icon: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: star <= _rating
                              ? const Color(0xFFE8A317)
                              : p.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final entry in _topicKeys.entries)
                      FilterChip(
                        label: Text(context.t(entry.value)),
                        selected: _topics.contains(entry.key),
                        showCheckmark: false,
                        selectedColor: p.brandSoft,
                        backgroundColor: p.surface,
                        side: BorderSide(
                          color: _topics.contains(entry.key)
                              ? p.brand
                              : p.border,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: _topics.contains(entry.key)
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: _topics.contains(entry.key)
                              ? p.brandDeep
                              : p.text,
                        ),
                        onSelected: _busy
                            ? null
                            : (value) => setState(() {
                                  value
                                      ? _topics.add(entry.key)
                                      : _topics.remove(entry.key);
                                }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    context.t('rate.note'),
                    style: TextStyle(color: p.textMuted, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _message,
                  enabled: !_busy,
                  maxLines: 3,
                  maxLength: 1000,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            SoftBanner(
              message: _error!,
              tone: Tone.danger,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_rating == 0 || _busy) ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(context.t('rate.submit')),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: p.textMuted,
            ),
            child: Text(context.t('rate.later')),
          ),
        ],
      ),
    );
  }
}
