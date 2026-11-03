import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:hammasir_student/core/storage/settings_store.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';

/// انواع فعالیت؛ کلید ترجمه‌ی هر کدام `act.<نوع>` است.
class ActivityType {
  ActivityType._();

  static const reserve = 'reserve';
  static const waitlist = 'waitlist';
  static const cancel = 'cancel';
  static const rate = 'rate';
  static const password = 'password';
  static const avatar = 'avatar';
  static const avatarRemoved = 'avatar_removed';
  static const biometricOn = 'biometric_on';
  static const biometricOff = 'biometric_off';
}

class ActivityEntry {
  const ActivityEntry({required this.type, required this.time, this.detail});

  final String type;
  final DateTime time;
  final String? detail;

  Map<String, dynamic> toJson() => {
        't': type,
        'at': time.toIso8601String(),
        if (detail != null) 'd': detail,
      };

  static ActivityEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final type = json['t'];
    final at = DateTime.tryParse('${json['at']}');
    if (type is! String || at == null) return null;
    final detail = json['d'];
    return ActivityEntry(
      type: type,
      time: at,
      detail: detail is String ? detail : null,
    );
  }
}

/// تاریخچه‌ی کارهایی که کاربر در برنامه انجام داده؛ جدیدترین‌ها اول.
/// فقط روی همین دستگاه نگه داشته می‌شود.
class ActivityStore extends ChangeNotifier with SafeNotifier {
  ActivityStore(this._store);

  static const int maxEntries = 200;

  final SettingsStore _store;

  int? _userId;
  List<ActivityEntry> _entries = const [];

  List<ActivityEntry> get entries => _entries;

  Future<void> load(int userId) async {
    _userId = userId;
    final raw = await _store.readActivity(userId);
    final list = <ActivityEntry>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final entry = ActivityEntry.fromJson(item);
            if (entry != null) list.add(entry);
          }
        }
      } catch (_) {
        // داده‌ی خراب نادیده گرفته می‌شود.
      }
    }
    list.sort((a, b) => b.time.compareTo(a.time));
    _entries = list;
    notifyListeners();
  }

  Future<void> record(String type, {String? detail}) async {
    final userId = _userId;
    if (userId == null) return;

    final next = [
      ActivityEntry(type: type, time: DateTime.now(), detail: detail),
      ..._entries,
    ].take(maxEntries).toList();
    _entries = next;
    notifyListeners();

    await _store.saveActivity(
      userId,
      jsonEncode([for (final e in next) e.toJson()]),
    );
  }
}
