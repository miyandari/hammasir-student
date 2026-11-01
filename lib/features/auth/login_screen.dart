import 'package:flutter/material.dart';

import 'package:hammasir_student/core/theme/app_palette.dart';
import 'package:hammasir_student/core/widgets/soft_banner.dart';
import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/state/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await widget.session.login(_username.text, _password.text);
    if (!mounted) return;
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final busy = widget.session.busy;
        final notice = widget.session.notice;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'هم‌مسیر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: p.brand,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ورود دانشجو',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted),
                        ),
                        const SizedBox(height: 32),
                        if (notice != null) ...[
                          SoftBanner(
                            message: notice,
                            tone: Tone.warning,
                            icon: Icons.info_outline,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _username,
                          enabled: !busy,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'نام کاربری',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'نام کاربری را وارد کنید'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          enabled: !busy,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          textDirection: TextDirection.ltr,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'رمز عبور',
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'نمایش رمز'
                                  : 'پنهان کردن رمز',
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'رمز عبور را وارد کنید'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          SoftBanner(
                            message: _error!,
                            tone: Tone.danger,
                            icon: Icons.error_outline,
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('ورود'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
