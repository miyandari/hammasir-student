import 'package:flutter/material.dart';

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
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';
import 'package:hammasir_student/features/trip/trip_controller.dart';
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
      title: 'لغو رزرو',
      message: 'رزرو این سفر لغو شود؟',
      confirmLabel: 'لغو رزرو',
      cancelLabel: 'نگه دار',
    );
    if (!ok || !mounted) return;

    try {
      await _stores.myTrips.cancel(booking.reservation.id);
      if (mounted) showMessage(context, 'رزرو لغو شد');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _stores.myTrips]),
      builder: (context, _) {
        final c = _controller;

        return Scaffold(
          appBar: AppBar(title: Text(c.service?.name ?? 'جزئیات سفر')),
          body: switch (c.status) {
            LoadStatus.idle || LoadStatus.loading => const CenteredLoader(),
            LoadStatus.error => ErrorState(
                message: c.error ?? 'خطا در دریافت سفر',
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
          child: RouteMap(stops: mapStops, vehicle: trip.isLive ? c.vehicle : null),
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
                  const SoftBanner(
                    message: 'به‌روزرسانی زنده قطع است؛ آخرین اطلاعات نمایش داده می‌شود.',
                    icon: Icons.cloud_off_outlined,
                  ),
                ],
                if (trip.isLive) ...[
                  const SizedBox(height: 12),
                  _LivePanel(controller: c, myStationId: myStationId),
                ],
                if (c.stops.isNotEmpty) ...[
                  const SectionTitle('ایستگاه‌ها'),
                  _StopList(controller: c, myStationId: myStationId),
                ],
                const SizedBox(height: 16),
                ..._actions(context, trip, booking),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, Trip trip, Booking? booking) {
    final widgets = <Widget>[];

    if (trip.isLive && booking != null) {
      widgets.add(
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyQrScreen()),
          ),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('نمایش کد QR من'),
        ),
      );
    }

    if (booking != null && trip.isOpen && booking.reservation.isLiveBooking) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(
        OutlinedButton(
          onPressed: () => _cancel(booking),
          child: const Text('لغو رزرو'),
        ),
      );
    }

    if (booking != null && booking.canRate) {
      widgets.add(
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RateTripScreen(booking: booking),
            ),
          ),
          icon: const Icon(Icons.star_rounded),
          label: const Text('امتیاز به این سفر'),
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
              if (booking != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: StatusChip(
                    label: StatusLabel.reservation(booking!.reservation.status).text,
                    tone: StatusLabel.reservation(booking!.reservation.status).tone,
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
      return const SoftBanner(
        message: 'موقعیت خودرو هنوز دریافت نشده است.',
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
            Text('تا ایستگاه شما', style: TextStyle(color: p.textMuted)),
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
                  ? 'ایستگاه بعدی: ${next.name}'
                  : 'ایستگاه بعدی: ${next.name} (${Fa.duration(next.etaSeconds!)})',
              style: TextStyle(color: p.text),
            )
          else
            Text('خودرو به آخرین ایستگاه رسیده است.',
                style: TextStyle(color: p.text)),
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
                    const StatusChip(label: 'ایستگاه شما', tone: Tone.warning),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
