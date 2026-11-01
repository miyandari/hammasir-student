import 'package:flutter/material.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأیید',
  String cancelLabel = 'انصراف',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
