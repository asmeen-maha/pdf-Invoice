/// App-wide configuration values.
class AppConfig {
  AppConfig._();

  static const String appTitle = 'PDF Invoice';
  static const String version = 'V0.1.0';

  /// Backend endpoint. Override at build time without touching code:
  /// `flutter build web --dart-define=API_URL=http://host/clientele_cm/marketing.php`
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://172.2.100.14/clientele_cm/marketing.php',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
