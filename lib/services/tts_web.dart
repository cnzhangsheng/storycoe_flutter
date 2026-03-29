/// Web Speech API implementation for Web platform
/// Uses package:web for proper Web API bindings

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Speak text using Web Speech API
Future<bool> speak({
  required String text,
  required double rate,
  required String lang,
  required void Function() onStart,
  required void Function() onEnd,
  required void Function(String error) onError,
}) async {
  try {
    // Check if Web Speech API is available
    if (web.window.speechSynthesis == null) {
      onError('Speech synthesis not available in this browser');
      return false;
    }

    // Cancel any ongoing speech
    web.window.speechSynthesis.cancel();

    // Create utterance
    final utterance = web.SpeechSynthesisUtterance(text);
    utterance.rate = rate;
    utterance.lang = lang;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;

    // Set up event handlers using completer
    final completer = Completer<bool>();

    utterance.onstart = ((web.Event event) {
      onStart();
    }).toJS;

    utterance.onend = ((web.Event event) {
      onEnd();
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }).toJS;

    utterance.onerror = ((web.SpeechSynthesisErrorEvent event) {
      onError(event.error ?? 'Unknown error');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }).toJS;

    // Speak
    web.window.speechSynthesis.speak(utterance);

    return true;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

/// Pause speech synthesis
void pause() {
  web.window.speechSynthesis.pause();
}

/// Cancel speech synthesis
void cancel() {
  web.window.speechSynthesis.cancel();
}