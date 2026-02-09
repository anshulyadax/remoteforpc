import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Neon realtime relay for remote control over internet
class NeonRelay {
  final SupabaseClient _client;
  final String deviceId;
  final bool isServer;
  
  RealtimeChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  NeonRelay({
    required SupabaseClient client,
    required this.deviceId,
    required this.isServer,
  }) : _client = client;

  /// Connect to relay channel
  Future<void> connect() async {
    final channelName = 'remote:$deviceId';
    
    _channel = _client.channel(channelName);

    // Listen for broadcast messages
    _channel!.onBroadcast(
      event: 'command',
      callback: (payload) {
        _messageController.add(Map<String, dynamic>.from(payload));
      },
    );

    // Subscribe to channel
    await _channel!.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('Connected to relay channel: $channelName');
        
        // Track presence
        _channel!.track({
          'deviceId': deviceId,
          'type': isServer ? 'server' : 'client',
          'online': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else if (error != null) {
        print('Error subscribing to channel: $error');
      }
    });
  }

  /// Disconnect from relay channel
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.untrack();
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Send command through relay
  Future<void> sendCommand(Map<String, dynamic> command) async {
    if (_channel == null) {
      throw Exception('Not connected to relay channel');
    }

    await _channel!.sendBroadcastMessage(
      event: 'command',
      payload: command,
    );
  }

  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Check if connected
  bool get isConnected => _channel != null;

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
