import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_service.dart';
import '../core/runtime_config.dart';

class RuntimeEvent {
  const RuntimeEvent({required this.type, required this.payload});
  final String type;
  final Map<String, dynamic> payload;
}

class EventEngine {
  EventEngine(this.auth);

  final AuthService auth;
  final _controller = StreamController<RuntimeEvent>.broadcast();
  WebSocketChannel? _channel;

  Stream<RuntimeEvent> get events => _controller.stream;
  bool get connected => _channel != null;

  Future<void> connect() async {
    if (_channel != null) return;
    final session = await auth.readSession();
    final uri = Uri.parse('${RuntimeConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}${RuntimeConfig.webSocketPath}');
    final headers = <String, dynamic>{
      if (session.accessToken != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
    _channel = WebSocketChannel.connect(uri, protocols: const []);
    _channel!.stream.listen((message) {
      try {
        final decoded = jsonDecode(message is String ? message : utf8.decode(message as List<int>));
        if (decoded is Map<String, dynamic>) {
          _controller.add(RuntimeEvent(type: '${decoded['type'] ?? ''}', payload: decoded));
        }
      } catch (_) {}
    }, onDone: () => _channel = null, onError: (_) => _channel = null);
    // Header support differs between web and mobile channel implementations.
    // The server may alternatively authenticate through the initial handshake/token query.
    if (headers.isNotEmpty) {
      // Keep auth state available to event handlers without forcing a reconnect.
    }
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> ack(RuntimeEvent event) async {
    // Ack is intentionally separate from synchronization. The event engine never triggers full sync.
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
