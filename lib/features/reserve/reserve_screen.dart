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
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/reserve/reserve_controller.dart';
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

    Navigator.of(context).pop();
    showMessage(
      context,
      reservation.isWaitlisted
          ? 'ظرفیت پر بود؛ در لیست انتظار قرار گرفتید'
          : 'رزرو شما ثبت شد',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;

        return Scaffold(
          appBar: AppBar(title: const Text('رزرو صندلی')),
          body: switch (c.status) {
            LoadStatus.idle || LoadStatus.loading => const CenteredLoader(),
            LoadStatus.error => ErrorState(
                message: c.error ?? 'خطا در دریافت اطلاعات',
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
                                  ? 'ثبت در لیست انتظار'
                                  : 'تأیید رزرو',
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
                widget.service.name,
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
              if (a != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: 'صندلی خالی: ${Fa.digits(a.seatedAvailable)}',
                      tone: a.hasSeat ? Tone.success : Tone.danger,
                    ),
                    if (a.allowStanding)
                      StatusChip(
                        label: 'ایستاده: ${Fa.digits(a.standingAvailable)}',
                        tone: a.hasStanding ? Tone.brand : Tone.neutral,
                      ),
                    if (a.waitlistCount > 0)
                      StatusChip(
                        label: 'لیست انتظار: ${Fa.digits(a.waitlistCount)}',
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
              child: RouteMap(stops: mapStops, interactive: false),
            ),
          ),
        ],
        const SectionTitle('ایستگاه سوار شدن'),
        if (c.stops.isEmpty)
          const SoftBanner(
            message: 'برای این سرویس ایستگاهی ثبت نشده است.',
            icon: Icons.info_outline,
          )
        else
          for (final info in c.stops)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                title: info.station.name,
                subtitle: info.stop.minutesFromStart == null
                    ? null
                    : '${Fa.digits(info.stop.minutesFromStart)} دقیقه بعد از شروع',
                selected: info.station.id == c.stationId,
                onTap: () => c.selectStation(info.station.id),
              ),
            ),
        const SectionTitle('نوع جا'),
        ChoiceTile(
          title: 'نشسته',
          selected: !c.standing,
          onTap: () => c.selectStanding(false),
        ),
        if (widget.trip.allowStanding) ...[
          const SizedBox(height: 8),
          ChoiceTile(
            title: 'ایستاده',
            selected: c.standing,
            onTap: () => c.selectStanding(true),
          ),
        ],
        if (c.willBeWaitlisted) ...[
          const SizedBox(height: 12),
          const SoftBanner(
            message:
                'ظرفیت این نوع جا پر است و رزرو شما در لیست انتظار ثبت می‌شود.',
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
