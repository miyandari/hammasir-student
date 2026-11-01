import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:hammasir_student/app/deps.dart';
import 'package:hammasir_student/app/stores.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/utils/persian.dart';
import 'package:hammasir_student/core/widgets/state_views.dart';

/// کد QR دانشجو برای نشان دادن به راننده.
class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  late final Deps _deps;
  late final Stores _stores;

  String? _token;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _deps = DepsScope.read(context);
    _stores = StoresScope.read(context);
    _load();
  }

  Future<void> _load() async {
    final studentId = _stores.session.studentId;
    if (studentId == null) {
      setState(() {
        _loading = false;
        _error = 'حساب شما به دانشجو متصل نیست';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _deps.students.qrToken(studentId);
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = _stores.session.profile;
    final student = _stores.session.student;

    return Scaffold(
      appBar: AppBar(title: const Text('کد QR من')),
      body: _loading
          ? const CenteredLoader()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      profile?.fullName ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    if (student != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'شماره دانشجویی: ${Fa.digits(student.studentNumber)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: p.border),
                        ),
                        child: QrImageView(
                          data: _token!,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'هنگام سوار شدن این کد را به راننده نشان دهید.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textMuted),
                    ),
                  ],
                ),
    );
  }
}
