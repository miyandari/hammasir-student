import 'package:flutter/material.dart';

import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

/// کارت یک رزرو در لیست‌ها.
class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.stationName,
    required this.onTap,
    this.trailing,
  });

  final Booking booking;
  final String? stationName;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context); // با تغییر زبان دوباره ساخته شود
    final p = context.palette;
    final trip = booking.trip;
    final tripLabel = StatusLabel.trip(trip.status);
    final reservationLabel = StatusLabel.reservation(booking.reservation.status);
    final showTrip = booking.reservation.isActive;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              ),
              StatusChip(
                label: showTrip ? tripLabel.text : reservationLabel.text,
                tone: showTrip ? tripLabel.tone : reservationLabel.tone,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Fa.dayAndTime(trip.plannedDeparture),
            style: TextStyle(color: p.textMuted),
          ),
          if (stationName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                context.t('booking.station', {'name': stationName}),
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(height: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}
