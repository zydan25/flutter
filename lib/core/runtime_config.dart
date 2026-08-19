class RuntimeConfig {
  static const String baseUrl = 'https://flutter.alattab.site';
  static const String legacyConfigPath = '/api/app-config';
  static const String bootstrapPath = '/runtime/bootstrap?app=flutter-app';
  static const String manifestPath = '/runtime/manifest?app=flutter-app';
  static const String resourcesPath = '/runtime/resources?app=flutter-app';
  static const String syncPath = '/runtime/sync?app=flutter-app';
  static const String eventsAckPath = '/runtime/events/ack';
  static const String webSocketPath = '/runtime/events/ws?app=flutter-app';
  static const String refreshTokenPath = '/runtime/auth/refresh';
  static const String notificationTokenPath = '/runtime/devices/register';
  static const String healthPath = '/runtime/health?app=flutter-app';

  static const String schemaVersion = '1';
  static const String runtimeVersion = '2.0.0';
}
