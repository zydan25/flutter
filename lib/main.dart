import 'package:flutter/material.dart';

import 'actions/action_engine.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'events/event_engine.dart';
import 'notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final services = await RuntimeBootstrap.initialize();
  final actionEngine = ActionEngine(
    api: services.api,
    store: services.store,
    sync: services.sync,
    auth: services.auth,
  );

  await initializeStac(actionEngine);

  final manifest = await services.sync.localManifest() ?? const <String, dynamic>{};
  final events = EventEngine(services.auth);
  try {
    await events.connect();
  } catch (_) {}

  final push = PushService(onAction: (action) {
    // Notification actions share the same server-defined Action Engine contract.
    // Navigation/dialog execution is attached to a foreground context by the shell.
  });
  await push.initialize();

  runApp(ServerDrivenApp(
    manifest: manifest,
    store: services.store,
    actionEngine: actionEngine,
    eventEngine: events,
    sync: services.sync,
  ));
}
