import 'dart:async';

/// Authentication event bus for handling global auth events
/// Used to notify the app when authentication state changes (e.g., token expired)
class AuthEventBus {
  static final AuthEventBus _instance = AuthEventBus._internal();
  factory AuthEventBus() => _instance;
  AuthEventBus._internal();

  final _logoutController = StreamController<void>.broadcast();
  final _tokenRefreshController = StreamController<void>.broadcast();

  /// Stream of logout events
  /// Subscribe to this to handle forced logout (e.g., when token expires)
  Stream<void> get onLogout => _logoutController.stream;

  /// Stream of token refresh events
  Stream<void> get onTokenRefresh => _tokenRefreshController.stream;

  /// Emit a logout event (called when authentication fails)
  void emitLogout() {
    _logoutController.add(null);
  }

  /// Emit a token refresh event
  void emitTokenRefresh() {
    _tokenRefreshController.add(null);
  }

  /// Dispose all controllers
  void dispose() {
    _logoutController.close();
    _tokenRefreshController.close();
  }
}

/// Global instance for easy access
final authEventBus = AuthEventBus();