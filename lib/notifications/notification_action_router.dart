import 'package:flutter/material.dart';

import '../actions/action_engine.dart';

class NotificationActionRouter {
  const NotificationActionRouter(this.engine);

  final ActionEngine engine;

  Future<dynamic> handle(BuildContext context, Map<String, dynamic> payload) {
    final action = payload['action'];
    if (action is Map) {
      return engine.execute(
        context,
        action.cast<String, dynamic>(),
        contextData: ActionContext(data: payload),
      );
    }
    return Future.value(null);
  }
}
