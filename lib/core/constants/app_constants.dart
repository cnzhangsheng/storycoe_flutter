/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'StoryBird';
  static const String appVersion = '1.0.0';

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Navigation routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String createRoute = '/create';
  static const String profileRoute = '/profile';
  static const String readingRoute = '/reading';

  // Mock data for development
  static const String defaultAvatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDpC6UIVMWH7qTni1WeLMvGYnIAXm30Ny9hehHPPW0Jybkf3fKa-fwj8IlVlJZxY2adUwEyjyqJhZF4s6wIFtpmg0286Yvo3GEXyIQOppB7_7bJvL7gkOGpf7ueEkQl2WsZWKlJIR4HnJYOlyTSvgBr8aI2rZ85hJyvbQOaH7dqazV_SwoPd0jR7c9_F-YoBQmzmWqUZRTSdBP54J89Zls3PB3-M4GD9Mw90J_p3wb2pEJlVxkW43I-wCIAJ7DkmASVttZbbCQ3sRE';
}