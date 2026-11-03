import 'package:flutter_test/flutter_test.dart';

import 'package:hammasir_student/data/models/live_eta.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/data/models/trip_availability.dart';
import 'package:hammasir_student/features/qr/scan_station_screen.dart';
import 'package:hammasir_student/features/shared/status_labels.dart';

void main() {
  group('Trip', () {
    test('پارس پاسخ سرور', () {
      final trip = Trip.fromJson({
        'id': 4,
        'service_id': 2,
        'status': 'boarding',
        'trip_date': '2026-05-10',
        'planned_departure_time': '2026-05-10T04:00:00Z',
        'allow_standing': true,
        'seated_capacity': 30,
        'standing_capacity': 5,
      });

      expect(trip.id, 4);
      expect(trip.isLive, isTrue);
      expect(trip.isFinished, isFalse);
      expect(trip.isOpen, isFalse);
      expect(trip.allowStanding, isTrue);
    });

    test('داده ناقص exception نمی‌دهد', () {
      final trip = Trip.fromJson({'id': 1});
      expect(trip.status, TripStatus.scheduled);
      expect(trip.isOpen, isTrue);
    });
  });

  group('Reservation', () {
    test('وضعیت‌ها', () {
      final waitlisted = Reservation.fromJson({
        'id': 1,
        'trip_id': 2,
        'status': 'waitlisted',
        'is_standing': false,
        'reservation_time': '2026-05-10T04:00:00Z',
      });
      expect(waitlisted.isLiveBooking, isTrue);
      expect(waitlisted.isActive, isFalse);

      final cancelled = Reservation.fromJson({'id': 2, 'status': 'cancelled'});
      expect(cancelled.isLiveBooking, isFalse);
    });
  });

  group('TripAvailability', () {
    test('پر بودن ظرفیت', () {
      final full = TripAvailability.fromJson({
        'seated_available': 0,
        'allow_standing': true,
        'standing_available': 0,
        'waitlist_count': 3,
      });
      expect(full.isFull, isTrue);

      final standingOnly = TripAvailability.fromJson({
        'seated_available': 0,
        'allow_standing': true,
        'standing_available': 2,
      });
      expect(standingOnly.isFull, isFalse);
      expect(standingOnly.hasSeat, isFalse);
    });
  });

  group('LiveEta', () {
    test('پارس و جستجوی ETA ایستگاه', () {
      final eta = LiveEta.fromJson({
        'vehicle_latitude': 35.7,
        'vehicle_longitude': 51.4,
        'eta_available': true,
        'gps_status': 'online',
        'next_station': {
          'station_id': 10,
          'station_name': 'الف',
          'eta_seconds': 120,
        },
        'upcoming_stations': [
          {'station_id': 11, 'station_name': 'ب', 'eta_seconds': 400},
        ],
      });

      expect(eta.vehicle, isNotNull);
      expect(eta.etaToStation(10), 120);
      expect(eta.etaToStation(11), 400);
      expect(eta.etaToStation(99), isNull);
      expect(eta.gpsOffline, isFalse);
    });

    test('بدون موقعیت', () {
      final eta = LiveEta.fromJson({'next_station': null});
      expect(eta.vehicle, isNull);
      expect(eta.next, isNull);
    });
  });

  group('parseStationCode', () {
    test('قالب‌های معتبر', () {
      expect(parseStationCode('station:12'), 12);
      expect(parseStationCode(' STATION:7 '), 7);
      expect(parseStationCode('15'), 15);
    });

    test('قالب‌های نامعتبر', () {
      expect(parseStationCode('abc'), isNull);
      expect(parseStationCode('station:'), isNull);
      expect(parseStationCode('0'), isNull);
      expect(parseStationCode(''), isNull);
    });
  });

  group('serviceAllowsGender', () {
    test('محدودیت جنسیت', () {
      expect(serviceAllowsGender('mixed', 'male'), isTrue);
      expect(serviceAllowsGender('female', 'male'), isFalse);
      expect(serviceAllowsGender('female', 'female'), isTrue);
      expect(serviceAllowsGender('female', null), isFalse);
      expect(serviceAllowsGender('mixed', null), isTrue);
    });
  });
}
