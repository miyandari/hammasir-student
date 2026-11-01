import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/app_card.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';
import 'package:hammasir_student/data/models/service_info.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/features/shared/page_header.dart';
import 'package:hammasir_student/features/shared/ui_helpers.dart';

/// استخراج شناسه‌ی ایستگاه از متن QR: «station:12» یا فقط «12».
int? parseStationCode(String raw) {
  final text = raw.trim();
  final match = RegExp(r'^(?:station:)?(\d+)$', caseSensitive: false)
      .firstMatch(text);
  if (match == null) return null;
  final id = int.tryParse(match.group(1)!);
  return (id == null || id <= 0) ? null : id;
}

/// سوار شدن بدون رزرو: QR ایستگاه را اسکن می‌کند، سفر فعال را انتخاب می‌کند
/// و درخواست سوار شدن برای تأیید راننده ارسال می‌شود.
class ScanStationScreen extends StatefulWidget {
  const ScanStationScreen({super.key});

  @override
  State<ScanStationScreen> createState() => _ScanStationScreenState();
}

class _ScanStationScreenState extends State<ScanStationScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _manual = TextEditingController();

  late final Deps _deps;

  int? _stationId;
  List<_LiveTrip>? _liveTrips;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _deps = DepsScope.read(context);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_stationId != null) return;

    for (final barcode in capture.barcodes) {
      final id = parseStationCode(barcode.rawValue ?? '');
      if (id != null) {
        _selectStation(id);
        return;
      }
    }
  }

  void _submitManual() {
    final id = parseStationCode(_manual.text);
    if (id == null) {
      setState(() => _error = 'کد ایستگاه معتبر نیست');
      return;
    }
    FocusScope.of(context).unfocus();
    _selectStation(id);
  }

  Future<void> _selectStation(int id) async {
    setState(() {
      _stationId = id;
      _liveTrips = null;
      _error = null;
    });
    await _scanner.stop();
    await _loadLiveTrips();
  }

  Future<void> _loadLiveTrips() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _deps.trips.byDate(DateTime.now()),
        _deps.catalog.services(),
      ]);
      final trips = results[0] as List<Trip>;
      final services = results[1] as Map<int, ServiceInfo>;

      if (!mounted) return;
      setState(() {
        _liveTrips = [
          for (final trip in trips)
            if (trip.isLive && services[trip.serviceId] != null)
              _LiveTrip(trip, services[trip.serviceId]!),
        ];
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  Future<void> _request(_LiveTrip item) async {
    final stationId = _stationId;
    if (stationId == null || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _deps.reservations.scanStation(
        tripId: item.trip.id,
        stationId: stationId,
        standing: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, 'درخواست شما برای تأیید راننده ارسال شد');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _stationId = null;
      _liveTrips = null;
      _error = null;
    });
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR ایستگاه')),
      body: _stationId == null ? _scanView(context) : _pickView(context),
    );
  }

  Widget _scanView(BuildContext context) {
    final p = context.palette;

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MobileScanner(controller: _scanner, onDetect: _onDetect),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'QR روی تابلوی ایستگاه را اسکن کنید، یا کد ایستگاه را بنویسید.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manual,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'کد ایستگاه',
                        errorText: _error,
                      ),
                      onSubmitted: (_) => _submitManual(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitManual,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 54),
                    ),
                    child: const Text('ادامه'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickView(BuildContext context) {
    final p = context.palette;
    final trips = _liveTrips;

    if (_busy && trips == null) return const CenteredLoader();

    if (trips == null) {
      return ErrorState(
        message: _error ?? 'خطا در دریافت سفرها',
        onRetry: _loadLiveTrips,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'ایستگاه شماره ${Fa.digits(_stationId)} انتخاب شد. سفر را انتخاب کنید:',
          style: TextStyle(color: p.text, height: 1.7),
        ),
        const SectionTitle('سفرهای در حال انجام'),
        if (trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'الان سفر فعالی وجود ندارد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted),
            ),
          )
        else
          for (final item in trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: _busy ? null : () => _request(item),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.service.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          Text(
                            Fa.time(item.trip.plannedDeparture),
                            style: TextStyle(color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: p.danger)),
          ),
        const SizedBox(height: 8),
        TextButton(onPressed: _reset, child: const Text('اسکن دوباره')),
      ],
    );
  }
}

class _LiveTrip {
  const _LiveTrip(this.trip, this.service);

  final Trip trip;
  final ServiceInfo service;
}
