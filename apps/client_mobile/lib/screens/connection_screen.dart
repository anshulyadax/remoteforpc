import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/client_state.dart';
import 'touchpad_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8888');
  bool _isConnecting = false;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();

    if (ip.isEmpty || portStr.isEmpty) {
      _showError('Please enter IP address and port');
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port < 1 || port > 65535) {
      _showError('Invalid port number');
      return;
    }

    setState(() => _isConnecting = true);

    final clientState = context.read<ClientState>();
    final success = await clientState.connectToServer(ip, port);

    setState(() => _isConnecting = false);

    if (success && mounted) {
      // Navigate to touchpad screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TouchpadScreen()),
      );
    } else if (mounted) {
      _showError('Failed to connect to server');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteForPC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.devices,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Connect to Server',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Manual IP entry
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Connection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Server IP Address',
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.computer),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '8888',
                        prefixIcon: Icon(Icons.settings_ethernet),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // QR Scanner (placeholder)
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement QR scanner
                _showError('QR scanner coming soon');
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 16),

            // Auto-discover (placeholder)
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement mDNS discovery
                _showError('Auto-discovery coming soon');
              },
              icon: const Icon(Icons.search),
              label: const Text('Auto-Discover'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
