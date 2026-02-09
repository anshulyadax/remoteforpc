import 'package:flutter/material.dart';
import 'dart:async';

/// Touchpad surface widget for capturing gestures
class TouchpadSurface extends StatefulWidget {
  final Function(double dx, double dy) onMove;
  final VoidCallback onTap;
  final Function(double dx, double dy) onScroll;

  const TouchpadSurface({
    super.key,
    required this.onMove,
    required this.onTap,
    required this.onScroll,
  });

  @override
  State<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends State<TouchpadSurface> {
  Offset? _lastPosition;
  int _pointerCount = 0;
  bool _isTap = false;
  Offset? _tapDownPosition;
  DateTime? _tapDownTime;
  final double _tapThreshold = 10.0; // pixels
  final Duration _tapMaxDuration = const Duration(milliseconds: 200);

  // For scroll gestures
  final Map<int, Offset> _pointerPositions = {};

  // Batching for mouse moves
  final List<Offset> _moveBatch = [];
  Timer? _batchTimer;

  @override
  void dispose() {
    _batchTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;
    _pointerPositions[event.pointer] = event.localPosition;

    if (_pointerCount == 1) {
      _lastPosition = event.localPosition;
      _tapDownPosition = event.localPosition;
      _tapDownTime = DateTime.now();
      _isTap = true;
    } else {
      _isTap = false;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    // Check if moved too much for tap
    if (_isTap && _tapDownPosition != null) {
      final distance =
          (event.localPosition - _tapDownPosition!).distance;
      if (distance > _tapThreshold) {
        _isTap = false;
      }
    }

    if (_pointerCount == 1) {
      // Single finger - mouse move
      if (_lastPosition != null) {
        final dx = event.localPosition.dx - _lastPosition!.dx;
        final dy = event.localPosition.dy - _lastPosition!.dy;

        _moveBatch.add(Offset(dx, dy));

        // Batch mouse moves for efficiency
        _batchTimer?.cancel();
        _batchTimer = Timer(const Duration(milliseconds: 16), () {
          if (_moveBatch.isNotEmpty) {
            double totalDx = 0;
            double totalDy = 0;
            for (final delta in _moveBatch) {
              totalDx += delta.dx;
              totalDy += delta.dy;
            }
            widget.onMove(totalDx, totalDy);
            _moveBatch.clear();
          }
        });
      }
      _lastPosition = event.localPosition;
    } else if (_pointerCount == 2) {
      // Two fingers - scroll
      final positions = _pointerPositions.values.toList();
      if (positions.length == 2) {
        final center = (positions[0] + positions[1]) / 2;
        if (_lastPosition != null) {
          final dx = center.dx - _lastPosition!.dx;
          final dy = center.dy - _lastPosition!.dy;
          widget.onScroll(dx, dy);
        }
        _lastPosition = center;
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerCount--;
    _pointerPositions.remove(event.pointer);

    // Check for tap gesture
    if (_isTap &&
        _tapDownTime != null &&
        DateTime.now().difference(_tapDownTime!) < _tapMaxDuration) {
      widget.onTap();
    }

    if (_pointerCount == 0) {
      _lastPosition = null;
      _tapDownPosition = null;
      _tapDownTime = null;
      _isTap = false;

      // Flush remaining batch
      _batchTimer?.cancel();
      if (_moveBatch.isNotEmpty) {
        double totalDx = 0;
        double totalDy = 0;
        for (final delta in _moveBatch) {
          totalDx += delta.dx;
          totalDy += delta.dy;
        }
        widget.onMove(totalDx, totalDy);
        _moveBatch.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: (event) {
          _pointerCount--;
          _pointerPositions.remove(event.pointer);
          if (_pointerCount == 0) {
            _lastPosition = null;
          }
        },
        child: Stack(
          children: [
            // Center hint
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Move your finger to control the mouse',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to click • Two fingers to scroll',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Pointer count indicator
            if (_pointerCount > 0)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_pointerCount finger${_pointerCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
