import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storycoe_flutter/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: StoryCoeApp(),
      ),
    );

    // Verify that the app loads
    expect(find.byType(StoryCoeApp), findsOneWidget);
  });
}