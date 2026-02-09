/// Coordinate transformation utilities for screen resolution mapping
library;

import '../models/connection.dart';

/// Coordinate transformer for mapping touch coordinates to screen coordinates
class CoordinateTransformer {
  final List<ScreenInfo> screens;
  final double clientWidth;
  final double clientHeight;

  CoordinateTransformer({
    required this.screens,
    required this.clientWidth,
    required this.clientHeight,
  });

  /// Get primary screen
  ScreenInfo get primaryScreen =>
      screens.firstWhere((s) => s.isPrimary, orElse: () => screens.first);

  /// Calculate scaling factor for relative movements
  double getScalingFactor({int? targetScreenId}) {
    final screen = targetScreenId != null
        ? screens.firstWhere((s) => s.id == targetScreenId,
            orElse: () => primaryScreen)
        : primaryScreen;

    // Calculate based on client touchpad size vs server screen size
    final scaleX = screen.width / clientWidth;
    final scaleY = screen.height / clientHeight;

    // Use average scaling factor
    return (scaleX + scaleY) / 2;
  }

  /// Transform relative coordinates (dx, dy) with sensitivity multiplier
  ({double dx, double dy}) transformRelative({
    required double dx,
    required double dy,
    double sensitivity = 1.0,
    int? targetScreenId,
  }) {
    final scale = getScalingFactor(targetScreenId: targetScreenId);
    return (
      dx: dx * scale * sensitivity,
      dy: dy * scale * sensitivity,
    );
  }

  /// Transform absolute coordinates from touchpad to screen position
  ({int x, int y}) transformAbsolute({
    required double touchX,
    required double touchY,
    int? targetScreenId,
  }) {
    final screen = targetScreenId != null
        ? screens.firstWhere((s) => s.id == targetScreenId,
            orElse: () => primaryScreen)
        : primaryScreen;

    // Map touch percentage to screen coordinates
    final percentX = touchX / clientWidth;
    final percentY = touchY / clientHeight;

    final screenX = screen.x + (percentX * screen.width).round();
    final screenY = screen.y + (percentY * screen.height).round();

    return (x: screenX, y: screenY);
  }

  /// Clamp coordinates to screen bounds
  ({int x, int y}) clampToScreen({
    required int x,
    required int y,
    int? targetScreenId,
  }) {
    final screen = targetScreenId != null
        ? screens.firstWhere((s) => s.id == targetScreenId,
            orElse: () => primaryScreen)
        : primaryScreen;

    return (
      x: x.clamp(screen.x, screen.x + screen.width - 1),
      y: y.clamp(screen.y, screen.y + screen.height - 1),
    );
  }

  /// Get screen at position
  ScreenInfo? getScreenAtPosition(int x, int y) {
    for (final screen in screens) {
      if (x >= screen.x &&
          x < screen.x + screen.width &&
          y >= screen.y &&
          y < screen.y + screen.height) {
        return screen;
      }
    }
    return null;
  }

  /// Get total virtual screen bounds (for multi-monitor setup)
  ({int minX, int minY, int maxX, int maxY}) getVirtualBounds() {
    if (screens.isEmpty) {
      return (minX: 0, minY: 0, maxX: 1920, maxY: 1080);
    }

    int minX = screens.first.x;
    int minY = screens.first.y;
    int maxX = screens.first.x + screens.first.width;
    int maxY = screens.first.y + screens.first.height;

    for (final screen in screens.skip(1)) {
      minX = minX < screen.x ? minX : screen.x;
      minY = minY < screen.y ? minY : screen.y;
      maxX = maxX > screen.x + screen.width ? maxX : screen.x + screen.width;
      maxY = maxY > screen.y + screen.height ? maxY : screen.y + screen.height;
    }

    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}

/// Scroll velocity calculator for smooth scrolling
class ScrollVelocity {
  static const double _defaultScrollMultiplier = 1.0;
  static const int _maxScrollPixels = 1000;

  /// Calculate scroll delta with velocity and acceleration
  static ({double dx, double dy}) calculate({
    required double deltaX,
    required double deltaY,
    double multiplier = _defaultScrollMultiplier,
    bool isPrecise = true,
  }) {
    // Apply multiplier
    double dx = deltaX * multiplier;
    double dy = deltaY * multiplier;

    // For non-precise (mouse wheel), use larger steps
    if (!isPrecise) {
      const wheelMultiplier = 10.0;
      dx *= wheelMultiplier;
      dy *= wheelMultiplier;
    }

    // Clamp to maximum
    dx = dx.clamp(-_maxScrollPixels, _maxScrollPixels).toDouble();
    dy = dy.clamp(-_maxScrollPixels, _maxScrollPixels).toDouble();

    return (dx: dx, dy: dy);
  }

  /// Invert scroll direction (Natural scrolling toggle)
  static ({double dx, double dy}) invert({
    required double dx,
    required double dy,
  }) {
    return (dx: -dx, dy: -dy);
  }
}
