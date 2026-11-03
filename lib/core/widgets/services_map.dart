import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_student/core/config/app_config.dart';
import 'package:hammasir_student/core/widgets/osm_map_view.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';

/// یک سرویس روی نقشه (خودرو یا ایستگاه شروع).
class MapPin {
  const MapPin({
    required this.id,
    required this.point,
    required this.live,
  });

  final int id;
  final LatLng point;

  /// خودرو همین الان در حرکت/سوارکردن است.
  final bool live;
}

/// نقشه‌ی سرویس‌های فعال؛ هر مارکر با لمس، رویداد [onPinTap] را می‌فرستد.
class ServicesMap extends StatelessWidget {
  const ServicesMap({
    super.key,
    required this.pins,
    required this.onPinTap,
    this.bottomInset = 0,
  });

  final List<MapPin> pins;
  final void Function(MapPin pin) onPinTap;

  /// فضای پوشیده‌شده با کشوی پایین؛ نقشه برای دیده شدن مارکرها همین‌قدر بالاتر کادر می‌شود.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {

    final points = pins.isEmpty
        ? [const LatLng(AppConfig.defaultLat, AppConfig.defaultLng)]
        : [for (final pin in pins) pin.point];
    final hasSpread = _hasSpread(points);

    return OsmMapView(
      buttonBottom: bottomInset + 16,
      key: ValueKey(pins.map((e) => '${e.id}:${e.live}').join(',')),
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: pins.isEmpty ? 13 : 14,
        initialCameraFit: hasSpread
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: EdgeInsets.fromLTRB(56, 96, 56, bottomInset + 40),
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      layers: [
        MarkerLayer(
          markers: [
            for (final pin in pins)
              Marker(
                point: pin.point,
                width: 52,
                height: 52,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPinTap(pin),
                  child: _PinDot(live: pin.live),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static bool _hasSpread(List<LatLng> points) {
    if (points.length < 2) return false;

    final first = points.first;
    for (final point in points) {
      if ((point.latitude - first.latitude).abs() > 0.0001 ||
          (point.longitude - first.longitude).abs() > 0.0001) {
        return true;
      }
    }
    return false;
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (live)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.brand.withValues(alpha: 0.18),
            ),
          ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0xFF11262B) : p.brand,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
