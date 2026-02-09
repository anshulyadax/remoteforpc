import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:remote_protocol/remote_protocol.dart';
import '../connection/websocket_client.dart';
import 'dart:async';

/// Client application state
class ClientState extends ChangeNotifier {
  final String deviceId;
  WebSocketClient? _webSocketClient;
  
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionMode _connectionMode = ConnectionMode.lan;
  String? _connectedServerIp;
  int? _connectedServerPort;
  List<ScreenInfo> _serverScreens = [];
  int? _selectedScreenId;
  
  // Settings
  double _mouseSensitivity = 1.0;
  double _scrollSensitivity = 1.0;
  bool _naturalScrolling = false;
  bool _hapticFeedback = true;

  ClientState({String? deviceId})
      : deviceId = deviceId ?? const Uuid().v4();

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  ConnectionMode get connectionMode => _connectionMode;
  String? get connectedServerIp => _connectedServerIp;
  int? get connectedServerPort => _connectedServerPort;
  List<ScreenInfo> get serverScreens => List.unmodifiable(_serverScreens);
  int? get selectedScreenId => _selectedScreenId;
  double get mouseSensitivity => _mouseSensitivity;
  double get scrollSensitivity => _scrollSensitivity;
  bool get naturalScrolling => _naturalScrolling;
  bool get hapticFeedback => _hapticFeedback;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected ||
      _connectionStatus == ConnectionStatus.authenticated;

  /// Connect to server via LAN WebSocket
  Future<bool> connectToServer(String ip, int port) async {
    if (isConnected) {
      await disconnect();
    }

    _connectionStatus = ConnectionStatus.connecting;
    _connectedServerIp = ip;
    _connectedServerPort = port;
    notifyListeners();

    try {
      _webSocketClient = WebSocketClient(
        serverUrl: 'ws://$ip:$port',
        deviceId: deviceId,
      );

      // Listen to connection status
      _webSocketClient!.connectionStatus.listen((status) {
        _connectionStatus = status;
        notifyListeners();
      });

      // Listen to handshake response
      _webSocketClient!.handshakeResponse.listen((response) {
        if (response.success && response.screens != null) {
          _serverScreens = response.screens!;
          _selectedScreenId = _serverScreens.firstWhere(
            (s) => s.isPrimary,
            orElse: () => _serverScreens.first,
          ).id;
          notifyListeners();
        }
      });

      // Connect
      await _webSocketClient!.connect();
      return true;
    } catch (e) {
      print('Connection error: $e');
      _connectionStatus = ConnectionStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    if (_webSocketClient != null) {
      await _webSocketClient!.disconnect();
      _webSocketClient = null;
    }
    _connectionStatus = ConnectionStatus.disconnected;
    _connectedServerIp = null;
    _connectedServerPort = null;
    _serverScreens = [];
    _selectedScreenId = null;
    notifyListeners();
  }

  /// Send mouse move event
  Future<void> sendMouseMove(double dx, double dy) async {
    if (!isConnected || _webSocketClient == null) return;

    final event = MouseMoveEvent(
      dx: dx * _mouseSensitivity,
      dy: dy * _mouseSensitivity,
      targetScreen: _selectedScreenId,
      deviceId: deviceId,
    );

    await _webSocketClient!.sendEvent(event);
  }

  /// Send mouse click event
  Future<void> sendMouseClick(String button, String action) async {
    if (!isConnected || _webSocketClient == null) return;

    final event = MouseClickEvent(
      button: button,
      action: action,
      deviceId: deviceId,
    );

    await _webSocketClient!.sendEvent(event);
  }

  /// Send scroll event
  Future<void> sendScroll(double dx, double dy) async {
    if (!isConnected || _webSocketClient == null) return;

    // Apply natural scrolling if enabled
    final scrollDx = _naturalScrolling ? -dx : dx;
    final scrollDy = _naturalScrolling ? -dy : dy;

    final event = ScrollEvent(
      dx: scrollDx * _scrollSensitivity,
      dy: scrollDy * _scrollSensitivity,
      isPrecise: true,
      deviceId: deviceId,
    );

    await _webSocketClient!.sendEvent(event);
  }

  /// Send key press event
  Future<void> sendKeyPress(String key, List<String> modifiers, String action) async {
    if (!isConnected || _webSocketClient == null) return;

    final event = KeyPressEvent(
      key: key,
      modifiers: modifiers,
      action: action,
      deviceId: deviceId,
    );

    await _webSocketClient!.sendEvent(event);
  }

  /// Send text event
  Future<void> sendText(String text) async {
    if (!isConnected || _webSocketClient == null) return;

    final event = KeyTextEvent(
      text: text,
      deviceId: deviceId,
    );

    await _webSocketClient!.sendEvent(event);
  }

  /// Update connection mode
  void setConnectionMode(ConnectionMode mode) {
    _connectionMode = mode;
    notifyListeners();
  }

  /// Update selected screen
  void setSelectedScreen(int screenId) {
    _selectedScreenId = screenId;
    notifyListeners();
  }

  /// Update mouse sensitivity
  void setMouseSensitivity(double sensitivity) {
    _mouseSensitivity = sensitivity.clamp(0.1, 3.0);
    notifyListeners();
  }

  /// Update scroll sensitivity
  void setScrollSensitivity(double sensitivity) {
    _scrollSensitivity = sensitivity.clamp(0.1, 3.0);
    notifyListeners();
  }

  /// Toggle natural scrolling
  void toggleNaturalScrolling() {
    _naturalScrolling = !_naturalScrolling;
    notifyListeners();
  }

  /// Toggle haptic feedback
  void toggleHapticFeedback() {
    _hapticFeedback = !_hapticFeedback;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
