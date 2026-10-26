import 'package:flutter/material.dart';

/// Potwierdzenie usunięcia (styl jak przy usuwaniu zdań). Zwraca `true` po kliknięciu DELETE.
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("DELETE"),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
