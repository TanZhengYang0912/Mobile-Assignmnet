import 'package:flutter/material.dart';

void showNetworkErrorSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text("Couldn't reach the server. Check your connection and try again."),
  ));
}
