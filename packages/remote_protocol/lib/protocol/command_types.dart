/// Command type constants for protocol messages
library;

/// Message types
class MessageType {
  static const String handshakeRequest = 'handshake_request';
  static const String handshakeResponse = 'handshake_response';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String event = 'event';
  static const String error = 'error';
  static const String ack = 'ack';
}

/// Event types
class EventType {
  static const String mouseMove = 'mouse_move';
  static const String mouseClick = 'mouse_click';
  static const String scroll = 'scroll';
  static const String keyPress = 'key_press';
  static const String keyText = 'key_text';
  static const String gesture = 'gesture';
  static const String mediaControl = 'media_control';
  static const String clipboard = 'clipboard';
}

/// Mouse button types
class MouseButton {
  static const String left = 'left';
  static const String right = 'right';
  static const String middle = 'middle';
}

/// Mouse/Key action types
class ActionType {
  static const String down = 'down';
  static const String up = 'up';
  static const String doubleClick = 'double';
}

/// Keyboard modifier keys
class ModifierKey {
  static const String command = 'cmd';
  static const String shift = 'shift';
  static const String control = 'ctrl';
  static const String alt = 'alt';
  static const String option = 'opt';
}

/// Gesture types
class GestureType {
  static const String pinch = 'pinch';
  static const String rotate = 'rotate';
  static const String swipe = 'swipe';
  static const String threeFingerSwipe = 'threeFingerSwipe';
  static const String fourFingerSwipe = 'fourFingerSwipe';
}

/// Media control actions
class MediaAction {
  static const String play = 'play';
  static const String pause = 'pause';
  static const String playPause = 'playPause';
  static const String previous = 'prev';
  static const String next = 'next';
  static const String volumeUp = 'volumeUp';
  static const String volumeDown = 'volumeDown';
  static const String mute = 'mute';
  static const String setVolume = 'setVolume';
}

/// Swipe directions
class SwipeDirection {
  static const String up = 'up';
  static const String down = 'down';
  static const String left = 'left';
  static const String right = 'right';
}

/// Device types
class DeviceType {
  static const String server = 'server';
  static const String client = 'client';
}

/// Platform types
class PlatformType {
  static const String macos = 'macos';
  static const String windows = 'windows';
  static const String ios = 'ios';
  static const String android = 'android';
}

/// Clipboard content types
class ClipboardContentType {
  static const String text = 'text';
  static const String image = 'image';
  static const String file = 'file';
}
