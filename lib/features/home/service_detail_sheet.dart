import 'package:flutter/material.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/station.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/models/trip_availability.dart';
import 'package:hammasir_student/features/home/home_controller.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

/// مشخصات یک سرویس بعد از لمس مارکر روی نقشه.
Future<void> showServiceDetailSheet(
  BuildContext context, {
  required TripOption option,
  required bool live,
  required Booking? booking,
  required bool blocked,
  required VoidCallback onReserve,
  required VoidCallback onOpenTrip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _ServiceDetail(
      option: option,
      live: live,
      booking: booking,
      blocked: blocked,
      onReserve: () {
        Navigator.of(sheetContext).pop();
        onReserve();
      },
      onOpenTrip: () {
        Navigator.of(sheetContext).pop();
        onOpenTrip();
      },
    ),
  );
}

class _ServiceDetail extends StatefulWidget {
  const _ServiceDetail({
    required this.option,
    required this.live,
    required this.booking,
    required this.blocked,
    required this.onReserve,
    required this.onOpenTrip,
  });

  final TripOption option;
  final bool live;
  final Booking? booking;
  final bool blocked;
  final VoidCallback onReserve;
  final VoidCallback onOpenTrip;

  @override
  State<_ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<_ServiceDetail> {
  List<RouteStationInfo> _stops = const [];
  TripAvailability? _availability;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deps = DepsScope.read(context);

    try {
      final results = await Future.wait([
        deps.catalog.routeStations(widget.option.service.routeId),
        deps.trips.availability(widget.option.trip.id),
      ]);
      if (!mounted) return;
      setState(() {
        _stops = results[0] as List<RouteStationInfo>;
        _availability = results[1] as TripAvailability?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final trip = widget.option.trip;
    final service = widget.option.service;
    final status = StatusLabel.trip(trip.status);
    final gender = StatusLabel.gender(service.genderRestriction);
    final a = _availability;
    final booked = widget.booking != null;
    final canReserve =
        !booked && !widget.blocked && trip.status == TripStatus.scheduled;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.option.title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
                StatusChip(label: status.text, tone: status.tone),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              Fa.dayAndTime(trip.plannedDeparture),
              style: TextStyle(color: p.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (gender != null)
                  StatusChip(label: gender.text, tone: gender.tone),
                if (widget.live)
                  StatusChip(
                    label: context.t('detail.vehicle_live'),
                    tone: Tone.success,
                  ),
                if (a != null) ...[
                  StatusChip(
                    label: context.t('reserve.seats_free', {
                      'n': Fa.digits(a.seatedAvailable),
                    }),
                    tone: a.hasSeat ? Tone.success : Tone.danger,
                  ),
                  if (a.allowStanding)
                    StatusChip(
                      label: context.t('reserve.standing_free', {
                        'n': Fa.digits(a.standingAvailable),
                      }),
                      tone: a.hasStanding ? Tone.brand : Tone.neutral,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_stops.length >= 2)
              Row(
                children: [
                  Icon(Icons.route, size: 20, color: p.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_stops.first.station.name}  ←  ${_stops.last.station.name}',
                      style: TextStyle(color: p.text),
                    ),
                  ),
                ],
              ),
            if (!_loading && _stops.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                context.t('detail.stops_count', {
                  'n': Fa.digits(_stops.length),
                }),
                style: TextStyle(fontSize: 13, color: p.textMuted),
              ),
            ],
            const SizedBox(height: 18),
            if (canReserve)
              FilledButton(
                onPressed: widget.onReserve,
                child: Text(context.t('home.reserve')),
              )
            else
              FilledButton(
                onPressed: widget.onOpenTrip,
                child: Text(
                  widget.live
                      ? context.t('home.live_status')
                      : context.t('detail.trip_details'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
