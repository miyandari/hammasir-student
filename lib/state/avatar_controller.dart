import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:hammasir_student/core/storage/settings_store.dart';
import 'package:hammasir_student/core/utils/safe_notifier.dart';

/// عکس پروفایل (فعلاً فقط روی همین دستگاه؛ آپلود به سرور نیاز به endpoint بک‌اند دارد).
class AvatarController extends ChangeNotifier with SafeNotifier {
  AvatarController(this._store);

  final SettingsStore _store;

  int? _userId;
  String? _path;
  bool _busy = false;

  String? get path => _path;
  bool get busy => _busy;

  Future<void> load(int userId) async {
    _userId = userId;
    final saved = await _store.readAvatarPath(userId);
    _path = (saved != null && File(saved).existsSync()) ? saved : null;
    notifyListeners();
  }

  /// انتخاب از گالری. true یعنی عکس جدید ذخیره شد؛ خطا را در [error] می‌گذارد.
  Future<bool> pickFromGallery() async {
    final userId = _userId;
    if (userId == null || _busy) return false;

    _busy = true;
    notifyListeners();

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return false;

      final dir = await getApplicationDocumentsDirectory();
      final target = File(
        '${dir.path}/avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(picked.path).copy(target.path);

      await _deleteOld();
      _path = target.path;
      await _store.saveAvatarPath(userId, _path);
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> remove() async {
    final userId = _userId;
    if (userId == null) return;

    await _deleteOld();
    _path = null;
    await _store.saveAvatarPath(userId, null);
    notifyListeners();
  }

  Future<void> _deleteOld() async {
    final old = _path;
    if (old == null) return;
    try {
      final file = File(old);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// با خروج از حساب، فقط حافظه‌ی کنترلر خالی می‌شود (فایل برای ورود بعدی می‌ماند).
  void clear() {
    _userId = null;
    _path = null;
    notifyListeners();
  }
}
