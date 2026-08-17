import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import '../sync/sync_engine.dart';

class RuntimeServices {
  RuntimeServices({
    required this.auth,
    required this.store,
    required this.api,
    required this.sync,
  });

  final AuthService auth;
  final DriftStore store;
  final ApiClient api;
  final SyncEngine sync;
}

class RuntimeBootstrap {
  static Future<RuntimeServices> initialize() async {
    const secureStorage = FlutterSecureStorage();
    final auth = AuthService(secureStorage);
    final directory = await getApplicationSupportDirectory();
    final store = DriftStore(File('${directory.path}/runtime.db'));
    await store.open();
    final api = ApiClient(
      accessTokenProvider: () async => (await auth.readSession()).accessToken,
    );
    final sync = SyncEngine(api: api, store: store);
    await sync.initialSync();
    return RuntimeServices(auth: auth, store: store, api: api, sync: sync);
  }
}
