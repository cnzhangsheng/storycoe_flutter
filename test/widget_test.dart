import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storycoe_flutter/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: StoryBirdApp(),
      ),
    );

    // Verify that the login screen appears
    expect(find.text('StoryBird'), findsWidgets);
  });
}