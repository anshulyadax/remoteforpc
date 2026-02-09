import 'package:flutter/services.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// Flutter-side input controller that communicates with native platform code
class InputController {
  static const MethodChannel _channel =
      MethodChannel('com.remoteforpc.input');

  /// Move mouse cursor relatively
  Future<bool> moveMouse(double dx, double dy) async {
    try {
      final result = await _channel.invokeMethod<bool>('moveMouse', {
        'dx': dx,
        'dy': dy,
      });
      return result ?? false;
    } catch (e) {
      print('Error moving mouse: $e');
      return false;
    }
  }

  /// Move mouse to absolute position
  Future<bool> moveMouseAbsolute(int x, int y) async {
    try {
      final result = await _channel.invokeMethod<bool>('moveMouseAbsolute', {
        'x': x,
        'y': y,
      });
      return result ?? false;
    } catch (e) {
      print('Error moving mouse absolute: $e');
      return false;
    }
  }

  /// Perform mouse click
  Future<bool> clickMouse({
    required String button,
    required String action,
    int? x,
    int? y,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('clickMouse', {
        'button': button,
        'action': action,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
      });
      return result ?? false;
    } catch (e) {
      print('Error clicking mouse: $e');
      return false;
    }
  }

  /// Perform scroll
  Future<bool> scroll(double dx, double dy, {bool isPrecise = true}) async {
    try {
      final result = await _channel.invokeMethod<bool>('scroll', {
        'dx': dx,
        'dy': dy,
        'isPrecise': isPrecise,
      });
      return result ?? false;
    } catch (e) {
      print('Error scrolling: $e');
      return false;
    }
  }

  /// Press keyboard key
  Future<bool> pressKey({
    required String key,
    required List<String> modifiers,
    required String action,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('pressKey', {
        'key': key,
        'modifiers': modifiers,
        'action': action,
      });
      return result ?? false;
    } catch (e) {
      print('Error pressing key: $e');
      return false;
    }
  }

  /// Type text
  Future<bool> typeText(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>('typeText', {
        'text': text,
      });
      return result ?? false;
    } catch (e) {
      print('Error typing text: $e');
      return false;
    }
  }

  /// Get all screen information
  Future<List<ScreenInfo>> getScreenInfo() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getScreenInfo');
      if (result == null) return [];
      
      return result.map((screen) {
        final map = Map<String, dynamic>.from(screen as Map);
        return ScreenInfo.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error getting screen info: $e');
      return [];
    }
  }

  /// Check if accessibility permissions are granted
  Future<bool> checkAccessibility() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAccessibility');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility: $e');
      return false;
    }
  }

  /// Request accessibility permissions
  Future<bool> requestAccessibility() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAccessibility');
      return result ?? false;
    } catch (e) {
      print('Error requesting accessibility: $e');
      return false;
    }
  }

  /// Open accessibility preferences
  Future<void> openAccessibilityPreferences() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilityPreferences');
    } catch (e) {
      print('Error opening accessibility preferences: $e');
    }
  }

  /// Process remote event and execute corresponding input action
  Future<bool> processEvent(RemoteEvent event) async {
    if (event is MouseMoveEvent) {
      return await moveMouse(event.dx, event.dy);
    } else if (event is MouseClickEvent) {
      return await clickMouse(
        button: event.button,
        action: event.action,
        x: event.x,
        y: event.y,
      );
    } else if (event is ScrollEvent) {
      return await scroll(event.dx, event.dy, isPrecise: event.isPrecise);
    } else if (event is KeyPressEvent) {
      return await pressKey(
        key: event.key,
        modifiers: event.modifiers,
        action: event.action,
      );
    } else if (event is KeyTextEvent) {
      return await typeText(event.text);
    }
    // TODO: Handle other event types (gesture, media, clipboard)
    return false;
  }
}
