import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../state/client_state.dart';
import '../widgets/touchpad_surface.dart';
import 'package:remote_protocol/remote_protocol.dart';

class TouchpadScreen extends StatefulWidget {
  const TouchpadScreen({super.key});

  @override
  State<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends State<TouchpadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ClientState>(
          builder: (context, state, _) {
            return Text(
              state.isConnected
                  ? 'Connected to ${state.connectedServerIp}'
                  : 'Disconnected',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Disconnect?'),
                  content: const Text('Are you sure you want to disconnect?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await context.read<ClientState>().disconnect();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Touchpad surface
          Expanded(
            flex: 3,
            child: TouchpadSurface(
              onMove: (dx, dy) {
                context.read<ClientState>().sendMouseMove(dx, dy);
              },
              onTap: () {
                _performClick(MouseButton.left);
              },
              onScroll: (dx, dy) {
                context.read<ClientState>().sendScroll(dx, dy);
              },
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mouse buttons row
                Row(
                  children: [
                    Expanded(
                      child: _buildMouseButton(
                        icon: Icons.touch_app,
                        label: 'Left',
                        onPressed: () => _performClick(MouseButton.left),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMouseButton(
                        icon: Icons.radio_button_unchecked,
                        label: 'Middle',
                        onPressed: () => _performClick(MouseButton.middle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMouseButton(
                        icon: Icons.touch_app,
                        label: 'Right',
                        onPressed: () => _performClick(MouseButton.right),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Additional controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.keyboard),
                      onPressed: () {
                        // TODO: Show keyboard
                      },
                      tooltip: 'Keyboard',
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.content_paste),
                      onPressed: () {
                        // TODO: Clipboard
                      },
                      tooltip: 'Clipboard',
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        // TODO: Media controls
                      },
                      tooltip: 'Media',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMouseButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _performClick(String button) async {
    final clientState = context.read<ClientState>();

    // Haptic feedback
    if (clientState.hapticFeedback) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 10);
        }
      });
    }

    // Send mouse down
    await clientState.sendMouseClick(button, ActionType.down);

    // Small delay
    await Future.delayed(const Duration(milliseconds: 50));

    // Send mouse up
    await clientState.sendMouseClick(button, ActionType.up);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
