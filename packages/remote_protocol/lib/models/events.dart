/// Event models for RemoteForPC protocol
library;

/// Base class for all remote control events
abstract class RemoteEvent {
  final String type;
  final DateTime timestamp;
  final String? deviceId;

  RemoteEvent({
    required this.type,
    DateTime? timestamp,
    this.deviceId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson();

  factory RemoteEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'mouse_move':
        return MouseMoveEvent.fromJson(json);
      case 'mouse_click':
        return MouseClickEvent.fromJson(json);
      case 'scroll':
        return ScrollEvent.fromJson(json);
      case 'key_press':
        return KeyPressEvent.fromJson(json);
      case 'key_text':
        return KeyTextEvent.fromJson(json);
      case 'gesture':
        return GestureEvent.fromJson(json);
      case 'media_control':
        return MediaControlEvent.fromJson(json);
      case 'clipboard':
        return ClipboardEvent.fromJson(json);
      default:
        throw UnimplementedError('Unknown event type: $type');
    }
  }
}

/// Mouse movement event (relative coordinates)
class MouseMoveEvent extends RemoteEvent {
  final double dx;
  final double dy;
  final int? targetScreen;

  MouseMoveEvent({
    required this.dx,
    required this.dy,
    this.targetScreen,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'mouse_move');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'dx': dx,
        'dy': dy,
        if (targetScreen != null) 'targetScreen': targetScreen,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory MouseMoveEvent.fromJson(Map<String, dynamic> json) => MouseMoveEvent(
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
        targetScreen: json['targetScreen'] as int?,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Mouse click event
class MouseClickEvent extends RemoteEvent {
  final String button; // 'left', 'right', 'middle'
  final String action; // 'down', 'up', 'double'
  final int? x;
  final int? y;

  MouseClickEvent({
    required this.button,
    required this.action,
    this.x,
    this.y,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'mouse_click');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'button': button,
        'action': action,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory MouseClickEvent.fromJson(Map<String, dynamic> json) =>
      MouseClickEvent(
        button: json['button'] as String,
        action: json['action'] as String,
        x: json['x'] as int?,
        y: json['y'] as int?,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Scroll event (relative scrolling)
class ScrollEvent extends RemoteEvent {
  final double dx;
  final double dy;
  final bool isPrecise; // true for trackpad, false for mouse wheel

  ScrollEvent({
    required this.dx,
    required this.dy,
    this.isPrecise = true,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'scroll');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'dx': dx,
        'dy': dy,
        'isPrecise': isPrecise,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory ScrollEvent.fromJson(Map<String, dynamic> json) => ScrollEvent(
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
        isPrecise: json['isPrecise'] as bool? ?? true,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Keyboard key press event
class KeyPressEvent extends RemoteEvent {
  final String key;
  final List<String> modifiers; // ['cmd', 'shift', 'ctrl', 'alt']
  final String action; // 'down', 'up'

  KeyPressEvent({
    required this.key,
    this.modifiers = const [],
    required this.action,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'key_press');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'key': key,
        'modifiers': modifiers,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory KeyPressEvent.fromJson(Map<String, dynamic> json) => KeyPressEvent(
        key: json['key'] as String,
        modifiers: List<String>.from(json['modifiers'] as List),
        action: json['action'] as String,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Text input event (bulk text typing)
class KeyTextEvent extends RemoteEvent {
  final String text;

  KeyTextEvent({
    required this.text,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'key_text');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory KeyTextEvent.fromJson(Map<String, dynamic> json) => KeyTextEvent(
        text: json['text'] as String,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Gesture event for trackpad gestures
class GestureEvent extends RemoteEvent {
  final String gestureType; // 'pinch', 'rotate', 'swipe'
  final Map<String, dynamic> data;

  GestureEvent({
    required this.gestureType,
    required this.data,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'gesture');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'gestureType': gestureType,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory GestureEvent.fromJson(Map<String, dynamic> json) => GestureEvent(
        gestureType: json['gestureType'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Media control event (play, pause, volume, etc.)
class MediaControlEvent extends RemoteEvent {
  final String action; // 'play', 'pause', 'prev', 'next', 'volumeUp', 'volumeDown', 'mute'
  final double? value; // for volume level (0.0 - 1.0)

  MediaControlEvent({
    required this.action,
    this.value,
    super.deviceId,
    super.timestamp,
  }) : super(type: 'media_control');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'action': action,
        if (value != null) 'value': value,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory MediaControlEvent.fromJson(Map<String, dynamic> json) =>
      MediaControlEvent(
        action: json['action'] as String,
        value: json['value'] != null ? (json['value'] as num).toDouble() : null,
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Clipboard synchronization event
class ClipboardEvent extends RemoteEvent {
  final String content;
  final String contentType; // 'text', 'image', 'file'

  ClipboardEvent({
    required this.content,
    this.contentType = 'text',
    super.deviceId,
    super.timestamp,
  }) : super(type: 'clipboard');

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'contentType': contentType,
        'timestamp': timestamp.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory ClipboardEvent.fromJson(Map<String, dynamic> json) => ClipboardEvent(
        content: json['content'] as String,
        contentType: json['contentType'] as String? ?? 'text',
        deviceId: json['deviceId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
