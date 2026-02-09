import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../server/websocket_server.dart';
import '../server/connection_manager.dart';
import '../server/event_handler.dart';
import '../server/input_controller.dart';

/// Server application state
class ServerState extends ChangeNotifier {
  final String deviceId;
  final InputController inputController;
  final ConnectionManager connectionManager;
  late final EventHandler eventHandler;
  late final WebSocketServer webSocketServer;

  bool _isServerRunning = false;
  bool _hasAccessibilityPermission = false;
  String? _serverIpAddress;
  int _serverPort = 8888;
  final List<String> _connectionLogs = [];

  ServerState({String? deviceId})
      : deviceId = deviceId ?? const Uuid().v4(),
        inputController = InputController(),
        connectionManager = ConnectionManager() {
    eventHandler = EventHandler(
      inputController: inputController,
      connectionManager: connectionManager,
    );
    webSocketServer = WebSocketServer(
      connectionManager: connectionManager,
      eventHandler: eventHandler,
      port: _serverPort,
    );

    _init();
  }

  Future<void> _init() async {
    // Check accessibility permissions
    _hasAccessibilityPermission = await inputController.checkAccessibility();
    notifyListeners();

    // Listen to connection events
    connectionManager.connectionEvents.listen((event) {
      _addLog('Client ${event.clientId} ${event.type.name}');
      notifyListeners();
    });

    // Listen to remote events for logging
    eventHandler.events.listen((event) {
      _addLog('Event: ${event.type}');
    });
  }

  // Getters
  bool get isServerRunning => _isServerRunning;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;
  String? get serverIpAddress => _serverIpAddress;
  int get serverPort => _serverPort;
  int get connectedClients => connectionManager.clientCount;
  List<String> get connectionLogs => List.unmodifiable(_connectionLogs);

  /// Start the server
  Future<void> startServer() async {
    if (_isServerRunning) return;

    final success = await webSocketServer.start();
    if (success) {
      _isServerRunning = true;
      _addLog('Server started on port $_serverPort');
      notifyListeners();
    }
  }

  /// Stop the server
  Future<void> stopServer() async {
    if (!_isServerRunning) return;

    await webSocketServer.stop();
    _isServerRunning = false;
    _addLog('Server stopped');
    notifyListeners();
  }

  /// Request accessibility permissions
  Future<void> requestAccessibilityPermission() async {
    final granted = await inputController.requestAccessibility();
    _hasAccessibilityPermission = granted;
    notifyListeners();
  }

  /// Open accessibility preferences
  Future<void> openAccessibilityPreferences() async {
    await inputController.openAccessibilityPreferences();
  }

  /// Update server port
  void updatePort(int port) {
    _serverPort = port;
    webSocketServer.setPort(port);
    notifyListeners();
  }

  /// Set server IP address (from network info)
  void setServerIp(String? ip) {
    _serverIpAddress = ip;
    notifyListeners();
  }

  /// Add connection log
  void _addLog(String message) {
    _connectionLogs.insert(0, '${DateTime.now().toIso8601String()}: $message');
    if (_connectionLogs.length > 100) {
      _connectionLogs.removeLast();
    }
  }

  /// Clear logs
  void clearLogs() {
    _connectionLogs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    webSocketServer.stop();
    connectionManager.dispose();
    eventHandler.dispose();
    super.dispose();
  }
}
