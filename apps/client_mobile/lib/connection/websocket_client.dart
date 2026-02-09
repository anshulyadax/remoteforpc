import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// WebSocket client for connecting to server
class WebSocketClient {
  final String serverUrl;
  final String deviceId;
  
  WebSocketChannel? _channel;
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<HandshakeResponse> _handshakeController =
      StreamController<HandshakeResponse>.broadcast();
  
  Timer? _pingTimer;

  WebSocketClient({
    required this.serverUrl,
    required this.deviceId,
  });

  /// Connection status stream
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  /// Handshake response stream
  Stream<HandshakeResponse> get handshakeResponse => _handshakeController.stream;

  /// Connect to WebSocket server
  Future<void> connect() async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      // Connect to WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('WebSocket error: $error');
          _updateStatus(ConnectionStatus.error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _updateStatus(ConnectionStatus.disconnected);
        },
      );

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Send handshake
      await _sendHandshake();

      _updateStatus(ConnectionStatus.connected);

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      print('Connection error: $e');
      _updateStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Send handshake request
  Future<void> _sendHandshake() async {
    final request = HandshakeRequest(
      deviceInfo: DeviceInfo(
        deviceId: deviceId,
        deviceName: 'Mobile Client',
        deviceType: DeviceType.client,
        platform: PlatformType.ios, // TODO: Detect platform
        version: '1.0.0',
      ),
      connectionMode: ConnectionMode.lan,
    );

    _sendMessage(request.toJson());
  }

  /// Send remote event
  Future<void> sendEvent(RemoteEvent event) async {
    if (_channel == null) {
      throw Exception('Not connected');
    }

    final message = {
      'type': 'event',
      'data': event.toJson(),
    };

    _sendMessage(message);
  }

  /// Send ping
  void _sendPing() {
    if (_channel == null) return;

    final ping = PingMessage(clientId: deviceId);
    _sendMessage(ping.toJson());
  }

  /// Send message to server
  void _sendMessage(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Handle incoming message
  void _handleMessage(dynamic message) {
    try {
      if (message is! String) return;

      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'handshake_response':
          final response = HandshakeResponse.fromJson(data);
          _handshakeController.add(response);
          if (response.success) {
            _updateStatus(ConnectionStatus.authenticated);
          }
          break;
        case 'pong':
          // Pong received, connection is alive
          break;
        case 'ack':
          // Event acknowledged
          break;
        case 'error':
          print('Server error: ${data['error']}');
          break;
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  /// Start ping timer for keepalive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendPing();
    });
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status) {
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _statusController.close();
    _handshakeController.close();
  }
}
