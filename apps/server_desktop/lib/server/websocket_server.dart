import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'connection_manager.dart';
import 'event_handler.dart';

/// WebSocket server for handling client connections
class WebSocketServer {
  final ConnectionManager connectionManager;
  final EventHandler eventHandler;
  late HttpServer _server;
  bool _isRunning = false;
  int _port;

  WebSocketServer({
    required this.connectionManager,
    required this.eventHandler,
    int port = 8888,
  }) : _port = port;

  /// Start the WebSocket server
  Future<bool> start() async {
    if (_isRunning) {
      print('Server already running');
      return false;
    }

    try {
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        _handleConnection(webSocket);
      });

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        _port,
      );

      _isRunning = true;
      print('WebSocket server started on port $_port');
      return true;
    } catch (e) {
      print('Failed to start server: $e');
      return false;
    }
  }

  /// Stop the WebSocket server
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      await _server.close(force: true);
      _isRunning = false;
      print('Server stopped');
    } catch (e) {
      print('Error stopping server: $e');
    }
  }

  /// Handle incoming WebSocket connection
  void _handleConnection(WebSocketChannel webSocket) {
    print('New client connection');
    
    final clientId = DateTime.now().millisecondsSinceEpoch.toString();
    connectionManager.addClient(clientId, webSocket);

    // Listen to incoming messages
    webSocket.stream.listen(
      (dynamic message) {
        _handleMessage(clientId, message);
      },
      onDone: () {
        print('Client $clientId disconnected');
        connectionManager.removeClient(clientId);
      },
      onError: (error) {
        print('Connection error for $clientId: $error');
        connectionManager.removeClient(clientId);
      },
    );
  }

  /// Handle incoming message from client
  void _handleMessage(String clientId, dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        eventHandler.handleMessage(clientId, data);
      } else {
        print('Received non-string message: $message');
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  /// Get server status
  bool get isRunning => _isRunning;

  /// Get server port
  int get port => _port;

  /// Update server port (requires restart)
  void setPort(int port) {
    _port = port;
  }
}
