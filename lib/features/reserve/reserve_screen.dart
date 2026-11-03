import 'package:flutter/material.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/choice_tile.dart';
import 'package:hammasir_student/core/widgets/route_map.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/reserve/reserve_controller.dart';
import 'package:hammasir_student/state/activity_store.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key, required this.trip, required this.service});

  final Trip trip;
  final ServiceInfo service;

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  String _query = '';

  late final ReserveController _controller;
  late final Stores _stores;

  @override
  void initState() {
    super.initState();
    final deps = DepsScope.read(context);
    _stores = StoresScope.read(context);
    _controller = ReserveController(
      trip: widget.trip,
      service: widget.service,
      studentId: _stores.session.studentId ?? 0,
      catalog: deps.catalog,
      trips: deps.trips,
      reservations: deps.reservations,
      routing: deps.routing,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reservation = await _controller.submit();
    if (!mounted || reservation == null) return;

    // نتیجه در همه‌ی صفحه‌ها (خانه و رزروها) تازه می‌شود.
    await _stores.myTrips.load();
    if (!mounted) return;

    final waitlisted = reservation.isWaitlisted;
    _stores.activity.record(
      waitlisted ? ActivityType.waitlist : ActivityType.reserve,
      detail: _controller.title,
    );
    final station = _controller.stationName(reservation.stationId);

    await showSuccess(
      context,
      title: waitlisted
          ? context.t('reserve.waitlisted_title')
          : context.t('reserve.done_title'),
      message: waitlisted
          ? context.t('reserve.waitlisted_msg')
          : context.t('reserve.done_msg'),
      buttonLabel: context.t('reserve.done_button'),
      extra: _SuccessSummary(
        service: _controller.title,
        when: Fa.dayAndTime(widget.trip.plannedDeparture),
        station: station,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;

        return Scaffold(
          appBar: AppBar(title: Text(context.t('reserve.title'))),
          body: switch (c.status) {
            LoadStatus.idle || LoadStatus.loading => const CenteredLoader(),
            LoadStatus.error => ErrorState(
                message: c.error ?? context.t('common.load_failed'),
                onRetry: c.load,
              ),
            LoadStatus.ready => _content(context, c, p),
          },
          bottomNavigationBar: c.status == LoadStatus.ready
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton(
                      onPressed: c.canSubmit ? _submit : null,
                      child: c.submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(
                              c.willBeWaitlisted
                                  ? context.t('reserve.submit_waitlist')
                                  : context.t('reserve.submit'),
                            ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _content(BuildContext context, ReserveController c, AppPalette p) {
    final a = c.availability;
    final mapStops = [
      for (final info in c.stops)
        if (info.station.point case final point?)
          MapStop(point: point, highlighted: info.station.id == c.stationId),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Fa.dayAndTime(widget.trip.plannedDeparture),
                style: TextStyle(color: p.textMuted),
              ),
              if (StatusLabel.gender(widget.service.genderRestriction)
                  case final gender?) ...[
                const SizedBox(height: 8),
                StatusChip(label: gender.text, tone: gender.tone),
              ],
              if (a != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
                    if (a.waitlistCount > 0)
                      StatusChip(
                        label: context.t('reserve.waitlist_count', {
                          'n': Fa.digits(a.waitlistCount),
                        }),
                        tone: Tone.warning,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (mapStops.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 180,
              child: RouteMap(
                stops: mapStops,
                path: c.path,
                interactive: false,
              ),
            ),
          ),
        ],
        SectionTitle(context.t('reserve.station')),
        if (c.stops.isEmpty)
          SoftBanner(
            message: context.t('reserve.no_stations'),
            icon: Icons.info_outline,
          )
        else
          if (c.stops.length > 4)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.t('reserve.search_station'),
                ),
              ),
            ),
          for (final info in c.stops.where(
            (i) => _query.isEmpty || i.station.name.contains(_query),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                title: info.station.name,
                subtitle: info.stop.minutesFromStart == null
                    ? null
                    : context.t('reserve.minutes_from_start', {
                        'n': Fa.digits(info.stop.minutesFromStart),
                      }),
                selected: info.station.id == c.stationId,
                onTap: () => c.selectStation(info.station.id),
              ),
            ),
        SectionTitle(context.t('reserve.seat_type')),
        ChoiceTile(
          title: context.t('reserve.seated'),
          selected: !c.standing,
          onTap: () => c.selectStanding(false),
        ),
        if (c.canChooseStanding) ...[
          const SizedBox(height: 8),
          ChoiceTile(
            title: context.t('reserve.standing'),
            selected: c.standing,
            onTap: () => c.selectStanding(true),
          ),
        ],
        if (c.willBeWaitlisted) ...[
          const SizedBox(height: 12),
          SoftBanner(
            message: context.t('reserve.waitlist_notice'),
            icon: Icons.hourglass_bottom,
          ),
        ],
        if (c.error != null) ...[
          const SizedBox(height: 12),
          SoftBanner(
            message: c.error!,
            tone: Tone.danger,
            icon: Icons.error_outline,
          ),
        ],
      ],
    );
  }
}

class _SuccessSummary extends StatelessWidget {
  const _SuccessSummary({
    required this.service,
    required this.when,
    required this.station,
  });

  final String service;
  final String when;
  final String? station;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service,
            style: TextStyle(fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 4),
          Text(when, style: TextStyle(color: p.textMuted)),
          if (station != null)
            Text(
              context.t('booking.station', {'name': station}),
              style: TextStyle(color: p.textMuted),
            ),
        ],
      ),
    );
  }
}
