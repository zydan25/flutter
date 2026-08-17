import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import '../sync/sync_engine.dart';

class RuntimeServices {
  RuntimeServices({required this.auth, required this.store, required this.api, required this.sync});

  final AuthService auth;
  final DriftStore store;
  final ApiClient api;
  final SyncEngine sync;
}

class RuntimeBootstrap {
  static Future<RuntimeServices> initialize() async {
    final auth = AuthService(const _StoragePlaceholder());
    // AuthService is replaced in main with its concrete secure storage instance.
    throw StateError('RuntimeBootstrap.initialize requires RuntimeBootstrap.initializeWithStorage');
  }

  static Future<RuntimeServices> initializeWithStorage(dynamic secureStorage) async {
    final auth = AuthService(secureStorage);
    final directory = await getApplicationSupportDirectory();
    final store = DriftStore(File('${directory.path}/runtime.db'));
    await store.open();
    final api = ApiClient(accessTokenProvider: () async => (await auth.readSession()).accessToken);
    final sync = SyncEngine(api: api, store: store);
    // This is the only automatic sync path: it executes only when no local snapshot exists.
    await sync.initialSync();
    return RuntimeServices(auth: auth, store: store, api: api, sync: sync);
  }
}

class _StoragePlaceholder implements dynamic {
  const _StoragePlaceholder();
}
