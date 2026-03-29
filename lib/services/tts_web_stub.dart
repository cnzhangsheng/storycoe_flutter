/// Stub implementation for non-web platforms
/// This file is used when dart.library.js_interop is not available

import 'dart:async';

Future<bool> speak({
  required String text,
  required double rate,
  required String lang,
  required VoidCallback onStart,
  required VoidCallback onEnd,
  required void Function(String error) onError,
}) async {
  // This should never be called on non-web platforms
  onError('Web Speech API is only available on web platform');
  return false;
}

void pause() {
  // No-op on non-web platforms
}

void cancel() {
  // No-op on non-web platforms
}