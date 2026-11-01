import 'package:flutter/material.dart';

import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/utils/load_status.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/features/rating/rate_trip_screen.dart';
import 'package:hammasir_student/features/shared/booking_tile.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/trip/trip_screen.dart';
import 'package:hammasir_student/state/my_trips_store.dart';

/// تب «رزروها»: پیش‌رو و تاریخچه.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: const [
          PageHeader(title: 'رزروهای من'),
          TabBar(
            tabs: [
              Tab(text: 'پیش رو'),
              Tab(text: 'تاریخچه'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BookingsList(history: false),
                BookingsList(history: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// لیست رزروها؛ هم در تب «رزروها» و هم در صفحه‌ی «تاریخچه‌ی سفرها» استفاده می‌شود.
class BookingsList extends StatelessWidget {
  const BookingsList({super.key, required this.history});

  final bool history;

  @override
  Widget build(BuildContext context) {
    final store = StoresScope.of(context).myTrips;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.status == LoadStatus.loading && store.upcoming.isEmpty &&
            store.history.isEmpty) {
          return const CenteredLoader();
        }

        if (store.status == LoadStatus.error) {
          return ErrorState(
            message: store.error ?? 'خطا در دریافت رزروها',
            onRetry: store.load,
          );
        }

        final items = history ? store.history : store.upcoming;

        return RefreshIndicator(
          onRefresh: store.load,
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  message: history
                      ? 'هنوز سفری در تاریخچه ندارید.'
                      : 'رزرو فعالی ندارید. از صفحه‌ی خانه رزرو کنید.',
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length + (store.offline ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (store.offline) {
                      if (index == 0) {
                        return const SoftBanner(
                          message: 'ارتباط با سرور برقرار نیست؛ آخرین اطلاعات نمایش داده می‌شود.',
                          icon: Icons.cloud_off_outlined,
                        );
                      }
                      index--;
                    }
                    return _tile(context, store, items[index]);
                  },
                ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, MyTripsStore store, Booking booking) {
    return BookingTile(
      booking: booking,
      stationName: store.stationName(booking.reservation.stationId),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TripScreen(tripId: booking.trip.id),
        ),
      ),
      trailing: booking.canRate
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RateTripScreen(booking: booking),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 40),
                ),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('امتیاز بده'),
              ),
            )
          : null,
    );
  }
}

/// صفحه‌ی مستقل تاریخچه‌ی سفرها (از صفحه‌ی «من»).
class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه سفرها')),
      body: const BookingsList(history: true),
    );
  }
}
