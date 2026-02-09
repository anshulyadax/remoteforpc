/// Connection and device models
library;

/// Connection mode enum
enum ConnectionMode {
  lan,
  remote,
  bluetooth;

  String toJson() => name;

  static ConnectionMode fromJson(String value) {
    return ConnectionMode.values.firstWhere((e) => e.name == value);
  }
}

/// Device information
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceType; // 'server' or 'client'
  final String platform; // 'macos', 'windows', 'ios', 'android'
  final String version;
  final Map<String, dynamic>? metadata;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.version,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'platform': platform,
        'version': version,
        if (metadata != null) 'metadata': metadata,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        deviceType: json['deviceType'] as String,
        platform: json['platform'] as String,
        version: json['version'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Screen information for multi-monitor support
class ScreenInfo {
  final int id;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool isPrimary;
  final double scaleFactor;

  ScreenInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isPrimary,
    this.scaleFactor = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'isPrimary': isPrimary,
        'scaleFactor': scaleFactor,
      };

  factory ScreenInfo.fromJson(Map<String, dynamic> json) => ScreenInfo(
        id: json['id'] as int,
        x: json['x'] as int,
        y: json['y'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        isPrimary: json['isPrimary'] as bool,
        scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Handshake request from client
class HandshakeRequest {
  final DeviceInfo deviceInfo;
  final String? pairingCode;
  final String? publicKey;
  final ConnectionMode connectionMode;

  HandshakeRequest({
    required this.deviceInfo,
    this.pairingCode,
    this.publicKey,
    required this.connectionMode,
  });

  Map<String, dynamic> toJson() => {
        'type': 'handshake_request',
        'deviceInfo': deviceInfo.toJson(),
        if (pairingCode != null) 'pairingCode': pairingCode,
        if (publicKey != null) 'publicKey': publicKey,
        'connectionMode': connectionMode.toJson(),
      };

  factory HandshakeRequest.fromJson(Map<String, dynamic> json) =>
      HandshakeRequest(
        deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
        pairingCode: json['pairingCode'] as String?,
        publicKey: json['publicKey'] as String?,
        connectionMode: ConnectionMode.fromJson(json['connectionMode'] as String),
      );
}

/// Handshake response from server
class HandshakeResponse {
  final bool success;
  final String? error;
  final DeviceInfo? serverInfo;
  final List<ScreenInfo>? screens;
  final String? publicKey;
  final String? sessionId;

  HandshakeResponse({
    required this.success,
    this.error,
    this.serverInfo,
    this.screens,
    this.publicKey,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'type': 'handshake_response',
        'success': success,
        if (error != null) 'error': error,
        if (serverInfo != null) 'serverInfo': serverInfo!.toJson(),
        if (screens != null) 'screens': screens!.map((s) => s.toJson()).toList(),
        if (publicKey != null) 'publicKey': publicKey,
        if (sessionId != null) 'sessionId': sessionId,
      };

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) =>
      HandshakeResponse(
        success: json['success'] as bool,
        error: json['error'] as String?,
        serverInfo: json['serverInfo'] != null
            ? DeviceInfo.fromJson(json['serverInfo'] as Map<String, dynamic>)
            : null,
        screens: json['screens'] != null
            ? (json['screens'] as List)
                .map((s) => ScreenInfo.fromJson(s as Map<String, dynamic>))
                .toList()
            : null,
        publicKey: json['publicKey'] as String?,
        sessionId: json['sessionId'] as String?,
      );
}

/// Connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  error;

  String toJson() => name;

  static ConnectionStatus fromJson(String value) {
    return ConnectionStatus.values.firstWhere((e) => e.name == value);
  }
}

/// Ping message for heartbeat
class PingMessage {
  final DateTime timestamp;
  final String? clientId;

  PingMessage({
    DateTime? timestamp,
    this.clientId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': 'ping',
        'timestamp': timestamp.toIso8601String(),
        if (clientId != null) 'clientId': clientId,
      };

  factory PingMessage.fromJson(Map<String, dynamic> json) => PingMessage(
        timestamp: DateTime.parse(json['timestamp'] as String),
        clientId: json['clientId'] as String?,
      );
}

/// Pong response
class PongMessage {
  final DateTime timestamp;
  final DateTime originalTimestamp;

  PongMessage({
    DateTime? timestamp,
    required this.originalTimestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': 'pong',
        'timestamp': timestamp.toIso8601String(),
        'originalTimestamp': originalTimestamp.toIso8601String(),
      };

  factory PongMessage.fromJson(Map<String, dynamic> json) => PongMessage(
        timestamp: DateTime.parse(json['timestamp'] as String),
        originalTimestamp: DateTime.parse(json['originalTimestamp'] as String),
      );
}
