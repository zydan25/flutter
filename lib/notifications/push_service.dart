import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  PushService({void Function(Map<String, dynamic>)? onAction}) : _onAction = onAction;

  final void Function(Map<String, dynamic>)? _onAction;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase configuration is optional until google-services/GoogleService-Info is provided.
    }
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _dispatch(message.data),
      );
      FirebaseMessaging.onMessage.listen((message) => _dispatch(message.data));
    } catch (_) {}
  }

  void _dispatch(Map<String, dynamic> data) {
    final action = data['action'];
    if (action is Map) {
      _onAction?.call(action.cast<String, dynamic>());
    }
  }
}
