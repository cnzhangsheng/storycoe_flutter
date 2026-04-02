import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StoryCoeApp(),
    ),
  );
}