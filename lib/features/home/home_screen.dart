import 'package:flutter/material.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/student_profile.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/home/home_controller.dart';
import 'package:hammasir_student/features/qr/my_qr_screen.dart';
import 'package:hammasir_student/features/qr/scan_station_screen.dart';
import 'package:hammasir_student/features/reserve/reserve_screen.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';
import 'package:hammasir_student/features/trip/trip_screen.dart';
import 'package:hammasir_student/state/my_trips_store.dart';
import 'package:hammasir_student/state/session_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
  }

  @override
  void dispose() {
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

  void _openTrip(int tripId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)),
    );
  }

  void _openReserve(TripOption option) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReserveScreen(trip: option.trip, service: option.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _myTrips, widget.session]),
      builder: (context, _) {
        final name = widget.session.profile?.firstName ??
            widget.session.profile?.fullName ??
            '';
        final student = widget.session.student;
        final next = _myTrips.next;
        final bookedTripIds = {
          for (final b in _myTrips.upcoming) b.trip.id,
        };
        final options = [
          for (final o in _controller.options)
            if (!bookedTripIds.contains(o.trip.id)) o,
        ];

        return Column(
          children: [
            PageHeader(
              title: name.isEmpty ? 'سلام' : 'سلام، $name',
              trailing: ActionChip(
                avatar: Icon(Icons.qr_code_2_rounded, size: 20, color: p.brand),
                label: const Text('کد من'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MyQrScreen()),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _body(context, student, next, options),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    StudentProfile? student,
    Booking? next,
    List<TripOption> options,
  ) {
    if (_controller.status == LoadStatus.loading &&
        _controller.options.isEmpty) {
      return const CenteredLoader();
    }

    if (_controller.status == LoadStatus.error && _controller.options.isEmpty) {
      return ErrorState(
        message: _controller.error ?? 'خطا در دریافت سفرها',
        onRetry: _controller.load,
      );
    }

    final offline = _controller.offline || _myTrips.offline;
    final blocked = student?.isBlocked == true;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (offline) ...[
          const SoftBanner(
            message: 'ارتباط با سرور برقرار نیست؛ آخرین اطلاعات نمایش داده می‌شود.',
            icon: Icons.cloud_off_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (blocked) ...[
          const SoftBanner(
            message: 'رزرو شما موقتاً مسدود است. جزئیات در صفحه‌ی «من».',
            tone: Tone.danger,
            icon: Icons.block,
          ),
          const SizedBox(height: 12),
        ],
        if (next != null) _NextTripCard(booking: next, onTap: _openTrip),
        const SectionTitle('اسکن QR ایستگاه'),
        AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ScanStationScreen(),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: context.palette.brand),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('سوار شدن بدون رزرو با اسکن QR ایستگاه'),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
        const SectionTitle('سفرهای پیش رو'),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'فعلاً سفری برای رزرو وجود ندارد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textMuted),
            ),
          )
        else
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TripOptionTile(
                option: option,
                blocked: blocked,
                onReserve: () => _openReserve(option),
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
    final label = StatusLabel.trip(trip.status);
    final isLive = trip.isLive;

    return AppCard(
      color: p.brand,
      borderColor: p.brand,
      onTap: () => onTap(trip.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'سفر بعدی شما',
                style: TextStyle(color: p.onBrand.withValues(alpha: 0.85)),
              ),
              const Spacer(),
              StatusChip(label: label.text, tone: label.tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: p.onBrand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Fa.dayAndTime(trip.plannedDeparture),
            style: TextStyle(color: p.onBrand.withValues(alpha: 0.9)),
          ),
          if (booking.reservation.isWaitlisted)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'در لیست انتظار هستید',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => onTap(trip.id),
            style: FilledButton.styleFrom(
              backgroundColor: p.onBrand,
              foregroundColor: p.brand,
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(isLive ? 'پیگیری زنده' : 'جزئیات سفر'),
          ),
        ],
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
    final label = StatusLabel.trip(trip.status);

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.service.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Fa.dayAndTime(trip.plannedDeparture),
                  style: TextStyle(color: p.textMuted),
                ),
                const SizedBox(height: 6),
                StatusChip(label: label.text, tone: label.tone),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: (blocked || trip.status != TripStatus.scheduled)
                ? null
                : onReserve,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              textStyle: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('رزرو'),
          ),
        ],
      ),
    );
  }
}
