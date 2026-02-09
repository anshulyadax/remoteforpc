import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages WebSocket client connections
class ConnectionManager {
  final Map<String, WebSocketChannel> _clients = {};
  final StreamController<ConnectionEvent> _connectionStreamController =
      StreamController<ConnectionEvent>.broadcast();

  /// Add a new client connection
  void addClient(String clientId, WebSocketChannel channel) {
    _clients[clientId] = channel;
    _connectionStreamController.add(ConnectionEvent(
      clientId: clientId,
      type: ConnectionEventType.connected,
    ));
  }

  /// Remove a client connection
  void removeClient(String clientId) {
    final channel = _clients.remove(clientId);
    channel?.sink.close();
    _connectionStreamController.add(ConnectionEvent(
      clientId: clientId,
      type: ConnectionEventType.disconnected,
    ));
  }

  /// Send message to a specific client
  void sendToClient(String clientId, Map<String, dynamic> message) {
    final client = _clients[clientId];
    if (client != null) {
      try {
        client.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending to client $clientId: $e');
        removeClient(clientId);
      }
    }
  }

  /// Broadcast message to all connected clients
  void broadcast(Map<String, dynamic> message) {
    final jsonMessage = jsonEncode(message);
    final deadClients = <String>[];

    for (final entry in _clients.entries) {
      try {
        entry.value.sink.add(jsonMessage);
      } catch (e) {
        print('Error broadcasting to ${entry.key}: $e');
        deadClients.add(entry.key);
      }
    }

    // Remove dead connections
    for (final clientId in deadClients) {
      removeClient(clientId);
    }
  }

  /// Get number of connected clients
  int get clientCount => _clients.length;

  /// Get list of connected client IDs
  List<String> get connectedClients => _clients.keys.toList();

  /// Connection events stream
  Stream<ConnectionEvent> get connectionEvents =>
      _connectionStreamController.stream;

  /// Dispose resources
  void dispose() {
    for (final client in _clients.values) {
      client.sink.close();
    }
    _clients.clear();
    _connectionStreamController.close();
  }
}

/// Connection event types
enum ConnectionEventType {
  connected,
  disconnected,
}

/// Connection event
class ConnectionEvent {
  final String clientId;
  final ConnectionEventType type;

  ConnectionEvent({
    required this.clientId,
    required this.type,
  });
}
