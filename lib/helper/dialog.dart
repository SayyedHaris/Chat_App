import 'package:flutter/material.dart';

class Dialogs {
  static void showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(textAlign: TextAlign.start, msg),
      backgroundColor: Colors.black.withOpacity(.8),
      behavior: SnackBarBehavior.fixed,
    ));
  }

  static void showProgressBar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}
