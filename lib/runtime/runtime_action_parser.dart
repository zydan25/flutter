import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stac_framework/stac_framework.dart';

import '../actions/action_engine.dart';

class RuntimeActionParser extends StacActionParser<Map<String, dynamic>> {
  RuntimeActionParser(this.engine);

  final ActionEngine engine;

  @override
  String get actionType => 'runtime_action';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  FutureOr<void> onCall(BuildContext context, Map<String, dynamic> model) {
    final action = model['action'];
    if (action is Map<String, dynamic>) {
      return engine.execute(context, action);
    }
    return null;
  }
}
