import '../core/runtime_config.dart';
import '../data/api/api_client.dart';
import 'auth_service.dart';

class AuthRefreshService {
  AuthRefreshService({required this.api, required this.auth});

  final ApiClient api;
  final AuthService auth;

  Future<bool> refresh() async {
    final refreshToken = await auth.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await api.request(
        method: 'POST',
        path: RuntimeConfig.refreshTokenPath,
        body: {'refresh_token': refreshToken},
        retries: 1,
        retryAfterUnauthorized: false,
      );
      if (response.statusCode != 200 || response.data is! Map) {
        return false;
      }
      final data = (response.data as Map).cast<String, dynamic>();
      final accessToken = data['access_token']?.toString();
      final nextRefresh = data['refresh_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }
      await auth.saveSession(
        accessToken: accessToken,
        refreshToken: nextRefresh ?? refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
