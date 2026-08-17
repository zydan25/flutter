import 'package:flutter/material.dart';

import 'actions/action_engine.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'device/capability_bridge.dart';
import 'events/event_engine.dart';
import 'notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final services = await RuntimeBootstrap.initialize();
  final capabilities = CapabilityBridge();
  final actionEngine = ActionEngine(
    api: services.api,
    store: services.store,
    sync: services.sync,
    auth: services.auth,
    capabilities: capabilities,
  );

  await initializeStac(actionEngine);

  final manifest =
      await services.sync.localManifest() ?? const <String, dynamic>{};
  final events = EventEngine(services.auth);
  try {
    await events.connect();
  } catch (_) {}

  final push = PushService(onAction: (action) {
    // Push actions are routed through the same server-defined action contract.
    // The app shell can execute them once a foreground BuildContext exists.
  });
  await push.initialize();

  runApp(
    ServerDrivenApp(
      manifest: manifest,
      store: services.store,
      actionEngine: actionEngine,
      eventEngine: events,
      sync: services.sync,
    ),
  );
}
