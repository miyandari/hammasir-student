import 'package:flutter/material.dart';

import 'package:hammasir_student/state/activity_store.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/route_map.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/qr/my_qr_screen.dart';
import 'package:hammasir_student/features/rating/rate_trip_screen.dart';
import 'package:hammasir_student/features/reserve/reserve_screen.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/features/trip/trip_controller.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late final TripController _controller;
  late final Stores _stores;

  @override
  void initState() {
    super.initState();
    final deps = DepsScope.read(context);
    _stores = StoresScope.read(context);
    _controller = TripController(
      tripId: widget.tripId,
      trips: deps.trips,
      catalog: deps.catalog,
      tracking: deps.tracking,
      routing: deps.routing,
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel(Booking booking) async {
    final ok = await confirm(
      context,
      icon: Icons.event_busy_rounded,
      title: context.t('trip.cancel_title'),
      message: context.t('trip.cancel_message'),
      confirmLabel: context.t('trip.cancel_confirm'),
      cancelLabel: context.t('trip.cancel_keep'),
      tone: Tone.danger,
      destructive: true,
    );
    if (!ok || !mounted) return;

    try {
      await _stores.myTrips.cancel(booking.reservation.id);
      _stores.activity.record(ActivityType.cancel, detail: _controller.title);
      if (mounted) {
        showMessage(context, context.t('trip.cancelled_done'), tone: Tone.success);
      }
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _stores.myTrips]),
      builder: (context, _) {
        final c = _controller;

        return Scaffold(
          appBar: AppBar(
            title: Text(c.title ?? context.t('trip.details')),
          ),
          body: switch (c.status) {
            LoadStatus.idle || LoadStatus.loading => const CenteredLoader(),
            LoadStatus.error => ErrorState(
                message: c.error ?? context.t('trip.load_failed'),
                onRetry: c.start,
              ),
            LoadStatus.ready => _content(context, c),
          },
        );
      },
    );
  }

  Widget _content(BuildContext context, TripController c) {
    final trip = c.trip!;
    final booking = _stores.myTrips.forTrip(trip.id);
    final myStationId = booking?.reservation.stationId;

    final mapStops = [
      for (final info in c.stops)
        if (info.station.point case final point?)
          MapStop(point: point, highlighted: info.station.id == myStationId),
    ];

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: RouteMap(
            stops: mapStops,
            path: c.path,
            vehicle: trip.isLive ? c.vehicle : null,
          ),
        ),
        Expanded(
          flex: 6,
          child: RefreshIndicator(
            onRefresh: c.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _Summary(trip: trip, booking: booking),
                if (c.stale) ...[
                  const SizedBox(height: 10),
                  SoftBanner(
                    message: context.t('trip.live_lost'),
                    icon: Icons.cloud_off_outlined,
                  ),
                ],
                if (trip.isLive) ...[
                  const SizedBox(height: 12),
                  _LivePanel(controller: c, myStationId: myStationId),
                ],
                if (c.stops.isNotEmpty) ...[
                  SectionTitle(context.t('trip.stations')),
                  _StopList(controller: c, myStationId: myStationId),
                ],
                const SizedBox(height: 16),
                ..._actions(context, c, trip, booking),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _actions(
    BuildContext context,
    TripController c,
    Trip trip,
    Booking? booking,
  ) {
    final widgets = <Widget>[];

    void gap() {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
    }

    if (trip.isLive && booking != null) {
      widgets.add(
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyQrScreen()),
          ),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: Text(context.t('trip.show_qr')),
        ),
      );
    }

    // رزرو مجدد: سفر هنوز باز است و رزرو فعالی ندارید (مثلاً لغو کرده‌اید).
    final service = c.service;
    if (booking == null && trip.isOpen && service != null) {
      gap();
      widgets.add(
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReserveScreen(trip: trip, service: service),
            ),
          ),
          icon: const Icon(Icons.event_available_rounded),
          label: Text(context.t('trip.reserve_this')),
        ),
      );
    }

    if (booking != null && trip.isOpen && booking.reservation.isLiveBooking) {
      gap();
      widgets.add(
        OutlinedButton(
          onPressed: () => _cancel(booking),
          child: Text(context.t('trip.cancel_reservation')),
        ),
      );
    }

    if (booking != null && booking.canRate) {
      gap();
      widgets.add(
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RateTripScreen(booking: booking),
            ),
          ),
          icon: const Icon(Icons.star_rounded),
          label: Text(context.t('trip.rate')),
        ),
      );
    }

    return widgets;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.trip, required this.booking});

  final Trip trip;
  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tripLabel = StatusLabel.trip(trip.status);
    final reservation = booking == null
        ? null
        : StatusLabel.reservation(booking!.reservation.status);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Fa.dayAndTime(trip.plannedDeparture),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              if (reservation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: StatusChip(
                    label: reservation.text,
                    tone: reservation.tone,
                  ),
                ),
            ],
          ),
        ),
        StatusChip(label: tripLabel.text, tone: tripLabel.tone),
      ],
    );
  }
}

class _LivePanel extends StatelessWidget {
  const _LivePanel({required this.controller, required this.myStationId});

  final TripController controller;
  final int? myStationId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final eta = controller.eta;

    if (eta == null || eta.gpsOffline) {
      return SoftBanner(
        message: context.t('trip.no_gps'),
        icon: Icons.gps_off,
      );
    }

    final next = eta.next;
    final mine = myStationId == null ? null : eta.etaToStation(myStationId!);

    return AppCard(
      color: p.brandSoft,
      borderColor: p.brandSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mine != null) ...[
            Text(
              context.t('trip.until_your_station'),
              style: TextStyle(color: p.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              Fa.duration(mine),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: p.brandDeep,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (next != null)
            Text(
              next.etaSeconds == null
                  ? context.t('trip.next_station', {'name': next.name})
                  : context.t('trip.next_station_eta', {
                      'name': next.name,
                      'eta': Fa.duration(next.etaSeconds!),
                    }),
              style: TextStyle(color: p.text),
            )
          else
            Text(
              context.t('trip.at_last_station'),
              style: TextStyle(color: p.text),
            ),
        ],
      ),
    );
  }
}

class _StopList extends StatelessWidget {
  const _StopList({required this.controller, required this.myStationId});

  final TripController controller;
  final int? myStationId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final nextId = controller.eta?.next?.stationId;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final info in controller.stops)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    info.station.id == nextId
                        ? Icons.directions_bus_rounded
                        : Icons.circle,
                    size: info.station.id == nextId ? 20 : 10,
                    color: info.station.id == myStationId ? p.accent : p.brand,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      info.station.name,
                      style: TextStyle(
                        color: p.text,
                        fontWeight: info.station.id == myStationId
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (info.station.id == myStationId)
                    StatusChip(
                      label: context.t('trip.your_station'),
                      tone: Tone.warning,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
