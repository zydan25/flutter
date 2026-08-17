import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/runtime_config.dart';
import '../data/api/api_client.dart';

class PushService {
  PushService({this.api, this._onAction, this._onToken});

  final ApiClient? api;
  final void Function(Map<String, dynamic>)? _onAction;
  final void Function(String token)? _onToken;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _publishToken(token);
      }

      _tokenSubscription = messaging.onTokenRefresh.listen(_publishToken);
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _dispatch(message.data),
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        (message) => _dispatch(message.data),
      );

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _dispatch(initial.data);
      }
    } catch (_) {
      // Firebase configuration is optional until platform configuration is supplied.
    }
  }

  Future<void> _publishToken(String token) async {
    _onToken?.call(token);
    final client = api;
    if (client == null) return;
    try {
      await client.request(
        method: 'POST',
        path: RuntimeConfig.notificationTokenPath,
        body: {'token': token},
        retries: 1,
      );
    } catch (_) {
      // Token publishing is best-effort; local notification support remains usable.
    }
  }

  void _dispatch(Map<String, dynamic> data) {
    final action = data['action'];
    if (action is Map) {
      _onAction?.call(action.cast<String, dynamic>());
    }
  }

  Future<void> dispose() async {
    await _openedSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
