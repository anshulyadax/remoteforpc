import 'dart:async';
import 'package:remote_protocol/remote_protocol.dart';
import 'input_controller.dart';
import 'connection_manager.dart';

/// Handles incoming messages and dispatches events
class EventHandler {
  final InputController inputController;
  final ConnectionManager connectionManager;
  final StreamController<RemoteEvent> _eventStreamController =
      StreamController<RemoteEvent>.broadcast();

  EventHandler({
    required this.inputController,
    required this.connectionManager,
  });

  /// Handle incoming message from client
  Future<void> handleMessage(String clientId, Map<String, dynamic> data) async {
    try {
      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'handshake_request':
          await _handleHandshake(clientId, data);
          break;
        case 'event':
          await _handleEvent(clientId, data);
          break;
        case 'ping':
          _handlePing(clientId, data);
          break;
        default:
          print('Unknown message type: $messageType');
      }
    } catch (e) {
      print('Error handling message from $clientId: $e');
    }
  }

  /// Handle handshake request
  Future<void> _handleHandshake(
      String clientId, Map<String, dynamic> data) async {
    try {
      // Get screen information
      final screens = await inputController.getScreenInfo();
      
      // Check accessibility permissions
      final hasAccess = await inputController.checkAccessibility();

      // Create response
      final response = HandshakeResponse(
        success: hasAccess,
        error: hasAccess ? null : 'Accessibility permission not granted',
        serverInfo: DeviceInfo(
          deviceId: 'server-${DateTime.now().millisecondsSinceEpoch}',
          deviceName: 'Server Desktop',
          deviceType: DeviceType.server,
          platform: PlatformType.macos,
          version: '1.0.0',
        ),
        screens: screens,
      );

      // Send response
      connectionManager.sendToClient(clientId, response.toJson());
    } catch (e) {
      print('Error handling handshake: $e');
      final errorResponse = HandshakeResponse(
        success: false,
        error: 'Handshake failed: $e',
      );
      connectionManager.sendToClient(clientId, errorResponse.toJson());
    }
  }

  /// Handle remote event
  Future<void> _handleEvent(String clientId, Map<String, dynamic> data) async {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      if (eventData == null) {
        print('No event data in message');
        return;
      }

      // Parse event
      final event = RemoteEvent.fromJson(eventData);
      _eventStreamController.add(event);

      // Process event
      final success = await inputController.processEvent(event);

      // Send acknowledgment
      connectionManager.sendToClient(clientId, {
        'type': 'ack',
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error handling event: $e');
      connectionManager.sendToClient(clientId, {
        'type': 'error',
        'error': 'Failed to process event: $e',
      });
    }
  }

  /// Handle ping message
  void _handlePing(String clientId, Map<String, dynamic> data) {
    try {
      final ping = PingMessage.fromJson(data);
      final pong = PongMessage(originalTimestamp: ping.timestamp);
      connectionManager.sendToClient(clientId, pong.toJson());
    } catch (e) {
      print('Error handling ping: $e');
    }
  }

  /// Event stream for monitoring
  Stream<RemoteEvent> get events => _eventStreamController.stream;

  /// Dispose resources
  void dispose() {
    _eventStreamController.close();
  }
}
