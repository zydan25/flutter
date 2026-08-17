import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  const Session({this.accessToken, this.refreshToken});
  final String? accessToken;
  final String? refreshToken;
}

class AuthService {
  AuthService(this.storage);

  final FlutterSecureStorage storage;
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  Future<Session> readSession() async => Session(
    accessToken: await storage.read(key: _access),
    refreshToken: await storage.read(key: _refresh),
  );

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    await storage.write(key: _access, value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: _refresh, value: refreshToken);
    }
  }

  Future<void> clear() async {
    await storage.delete(key: _access);
    await storage.delete(key: _refresh);
  }
}
