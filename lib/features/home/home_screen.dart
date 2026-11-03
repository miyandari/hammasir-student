import 'package:flutter/material.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/services_map.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/student_profile.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/home/home_controller.dart';
import 'package:hammasir_student/features/home/service_detail_sheet.dart';
import 'package:hammasir_student/features/qr/my_qr_screen.dart';
import 'package:hammasir_student/features/qr/scan_station_screen.dart';
import 'package:hammasir_student/features/reserve/reserve_screen.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/features/trip/trip_screen.dart';
import 'package:hammasir_student/l10n/l10n.dart';
import 'package:hammasir_student/state/my_trips_store.dart';
import 'package:hammasir_student/state/session_controller.dart';

/// خانه: نقشه‌ی سرویس‌های فعال + کشوی پایین (سفر بعدی و سفرهای قابل رزرو).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _sheetInitial = 0.46;

  late final HomeController _controller;
  late final MyTripsStore _myTrips;

  @override
  void initState() {
    super.initState();
    final deps = DepsScope.read(context);
    _myTrips = StoresScope.read(context).myTrips;
    _controller = HomeController(
      trips: deps.trips,
      catalog: deps.catalog,
      gender: () => widget.session.gender,
    )..load();
    widget.session.addListener(_onSessionChanged);
  }

  /// جنسیت بعد از ورود (از /students) می‌رسد؛ لیست باید دوباره فیلتر شود.
  String? _lastGender;

  void _onSessionChanged() {
    final gender = widget.session.gender;
    if (gender != _lastGender) {
      _lastGender = gender;
      _controller.load();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _controller.load(),
      _myTrips.load(),
      widget.session.refreshStudent(),
    ]);
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openReserve(TripOption option) {
    _push(ReserveScreen(trip: option.trip, service: option.service));
  }

  Future<void> _onPinTap(MapPin pin) async {
    final option = _controller.optionForPin(pin.id);
    if (option == null) return;

    await showServiceDetailSheet(
      context,
      option: option,
      live: pin.live,
      booking: _myTrips.forTrip(option.trip.id),
      blocked: widget.session.student?.isBlocked == true,
      onReserve: () => _openReserve(option),
      onOpenTrip: () => _push(TripScreen(tripId: option.trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final height = MediaQuery.sizeOf(context).height;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _myTrips, widget.session]),
      builder: (context, _) {
        final loading = _controller.status == LoadStatus.loading &&
            _controller.options.isEmpty;
        final failed = _controller.status == LoadStatus.error &&
            _controller.options.isEmpty;

        return Stack(
          children: [
            Positioned.fill(
              child: ServicesMap(
                pins: _controller.pins,
                onPinTap: _onPinTap,
                bottomInset: height * _sheetInitial,
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _FloatingChip(
                    icon: Icons.qr_code_2_rounded,
                    label: context.t('home.my_code'),
                    onTap: () => _push(const MyQrScreen()),
                  ),
                  const Spacer(),
                  _FloatingChip(
                    icon: Icons.refresh_rounded,
                    label: context.t('common.refresh'),
                    onTap: _refresh,
                  ),
                ],
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: _sheetInitial,
              minChildSize: 0.2,
              maxChildSize: 0.92,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: p.text.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: loading
                      ? const CenteredLoader()
                      : failed
                          ? ErrorState(
                              message: _controller.error ??
                                  context.t('home.load_failed'),
                              onRetry: _controller.load,
                            )
                          : _SheetContent(
                              controller: scrollController,
                              home: _controller,
                              myTrips: _myTrips,
                              student: widget.session.student,
                              onOpenTrip: (id) => _push(TripScreen(tripId: id)),
                              onReserve: _openReserve,
                              onScan: () => _push(const ScanStationScreen()),
                            ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: p.surface,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: p.brand),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.controller,
    required this.home,
    required this.myTrips,
    required this.student,
    required this.onOpenTrip,
    required this.onReserve,
    required this.onScan,
  });

  final ScrollController controller;
  final HomeController home;
  final MyTripsStore myTrips;
  final StudentProfile? student;
  final void Function(int tripId) onOpenTrip;
  final void Function(TripOption option) onReserve;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final next = myTrips.next;
    final blocked = student?.isBlocked == true;
    final booked = {for (final b in myTrips.upcoming) b.trip.id};
    // فقط سفرهایی که همین الان قابل رزرو هستند: باز، هنوز حرکت نکرده، رزرو نشده
    // و دانشجو مسدود نیست.
    final now = DateTime.now();
    final options = [
      for (final o in home.options)
        if (!blocked &&
            o.trip.isOpen &&
            o.trip.plannedDeparture.isAfter(now) &&
            !booked.contains(o.trip.id))
          o,
    ];
    final offline = home.offline || myTrips.offline;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (offline) ...[
          SoftBanner(
            message: context.t('common.offline_banner'),
            icon: Icons.cloud_off_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (blocked) ...[
          SoftBanner(
            message: context.t('home.blocked'),
            tone: Tone.danger,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
        ],
        if (next != null) ...[
          _NextTripCard(booking: next, onTap: onOpenTrip),
          const SizedBox(height: 16),
        ],
        Text(
          context.t('home.bookable'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
        ),
        const SizedBox(height: 10),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              context.t('home.no_trips'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted),
            ),
          )
        else
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TripOptionTile(
                option: option,
                blocked: blocked,
                onReserve: () => onReserve(option),
              ),
            ),
        const SizedBox(height: 8),
        AppCard(
          onTap: onScan,
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: p.brand),
              const SizedBox(width: 12),
              Expanded(child: Text(context.t('home.scan_station'))),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextTripCard extends StatelessWidget {
  const _NextTripCard({required this.booking, required this.onTap});

  final Booking booking;
  final void Function(int tripId) onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final trip = booking.trip;
    final reservation = StatusLabel.reservation(booking.reservation.status);
    final seat = booking.reservation.isStanding
        ? context.t('reserve.standing')
        : context.t('reserve.seated');

    return Material(
      color: p.brandSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(trip.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.t('home.next_trip'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.brandDeep,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reservation.text} · $seat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                booking.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: p.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    Fa.dayAndTime(trip.plannedDeparture),
                    style: TextStyle(color: p.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    trip.isLive
                        ? context.t('home.live_status')
                        : context.t('home.trip_status'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.brand,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.brand),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripOptionTile extends StatelessWidget {
  const _TripOptionTile({
    required this.option,
    required this.blocked,
    required this.onReserve,
  });

  final TripOption option;
  final bool blocked;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final trip = option.trip;
    final gender = StatusLabel.gender(option.service.genderRestriction);
    final canReserve = !blocked && trip.status == TripStatus.scheduled;
    final status = StatusLabel.trip(trip.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                if (option.route != null && option.route!.intermediate > 0)
                  Text(
                    context.t('service.stops_between', {
                      'n': Fa.digits(option.route!.intermediate),
                    }),
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                const SizedBox(height: 2),
                Text(
                  Fa.dayAndTime(trip.plannedDeparture),
                  style: TextStyle(fontSize: 13, color: p.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (!canReserve || trip.status != TripStatus.scheduled)
                      StatusChip(label: status.text, tone: status.tone),
                    if (gender != null)
                      StatusChip(label: gender.text, tone: gender.tone),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canReserve ? onReserve : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(76, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(context.t('home.reserve')),
          ),
        ],
      ),
    );
  }
}
