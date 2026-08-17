import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_service.dart';
import '../core/runtime_config.dart';
import '../data/api/api_client.dart';

class RuntimeEvent {
  const RuntimeEvent({
    required this.type,
    required this.payload,
    this.eventId,
  });
  final String type;
  final Map<String, dynamic> payload;
  final String? eventId;
}

class EventEngine {
  EventEngine(this.auth, {ApiClient? api}) : api = api;

  final AuthService auth;
  final ApiClient? api;
  final _controller = StreamController<RuntimeEvent>.broadcast();
  Timer? _reconnectTimer;
  WebSocketChannel? _channel;
  bool _disposed = false;
  int _attempt = 0;

  Stream<RuntimeEvent> get events => _controller.stream;
  bool get connected => _channel != null;

  Future<void> connect() async {
    if (_disposed || _channel != null) return;
    final session = await auth.readSession();
    final base = Uri.parse(
      '${RuntimeConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}${RuntimeConfig.webSocketPath}',
    );
    final uri = session.accessToken == null || session.accessToken!.isEmpty
        ? base
        : base.replace(
            queryParameters: {
              ...base.queryParameters,
              'access_token': session.accessToken!,
            },
          );

    try {
      final channel = WebSocketChannel.connect(uri, protocols: const []);
      _channel = channel;
      _attempt = 0;
      channel.stream.listen(
        (message) => _handleMessage(message),
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(
        message is String ? message : utf8.decode(message as List<int>),
      );
      if (decoded is Map<String, dynamic>) {
        _controller.add(
          RuntimeEvent(
            type: '${decoded['type'] ?? ''}',
            payload: decoded,
            eventId: decoded['event_id']?.toString(),
          ),
        );
      }
    } catch (_) {
      // Malformed realtime payloads are ignored without destabilizing the runtime.
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    if (_disposed || _reconnectTimer != null) return;
    final seconds = (1 << _attempt.clamp(0, 5));
    _attempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      unawaited(connect());
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> ack(RuntimeEvent event) async {
    final eventId = event.eventId;
    if (eventId == null || eventId.isEmpty || api == null) return;
    await api!.request(
      method: 'POST',
      path: RuntimeConfig.eventsAckPath,
      body: {
        'event_id': eventId,
        'event_type': event.type,
      },
      retries: 1,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _controller.close();
  }
}
