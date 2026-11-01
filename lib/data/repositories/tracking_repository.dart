import 'dart:async';
import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:hammasir_student/core/config/app_config.dart';
import 'package:hammasir_student/core/storage/token_store.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';

/// دریافت زنده‌ی موقعیت خودرو از WebSocket.
///
/// محدودیت بک‌اند: توکن باید در query string برود. اگر اتصال قطع شد یا
/// ناموفق بود، استریم تمام می‌شود و کنترلر به polling برمی‌گردد.
class TrackingRepository {
  TrackingRepository(this._tokens);

  final TokenStore _tokens;

  Uri _socketUri(int tripId, String token) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/trips/$tripId/location',
      queryParameters: {'token': token},
    );
  }

  /// استریم موقعیت‌ها. بعد از اتمام یا خطا بسته می‌شود.
  Stream<LatLng> locations(int tripId) async* {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) return;

    final channel = WebSocketChannel.connect(_socketUri(tripId, token));

    try {
      await channel.ready;

      await for (final raw in channel.stream) {
        final point = _parse(raw);
        if (point != null) yield point;
      }
    } finally {
      unawaited(channel.sink.close());
    }
  }

  LatLng? _parse(dynamic raw) {
    try {
      final map = asMap(jsonDecode(raw.toString()));
      if (map == null || map['type'] == 'error') return null;

      final lat = asDouble(map['latitude']);
      final lng = asDouble(map['longitude']);
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
