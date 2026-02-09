import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../state/server_state.dart';
import 'settings_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _startServerAutomatically();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check accessibility when screen comes into focus
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    final serverState = context.read<ServerState>();
    await serverState.checkAccessibilityStatus();
  }

  Future<void> _loadNetworkInfo() async {
    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();
    if (mounted) {
      context.read<ServerState>().setServerIp(wifiIP);
    }
  }

  Future<void> _startServerAutomatically() async {
    final serverState = context.read<ServerState>();
    
    // Check accessibility first
    if (!serverState.hasAccessibilityPermission) {
      _showAccessibilityDialog();
      return;
    }

    // Start server
    await serverState.startServer();
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RemoteForPC needs accessibility permissions to control your mouse and keyboard from your phone.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Follow these steps:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogStep(1, 'Click "Open Settings" below'),
                    _buildDialogStep(2, 'Click the lock icon 🔒'),
                    _buildDialogStep(3, 'Enter your Mac password'),
                    _buildDialogStep(4, 'Find "server_desktop" in the list'),
                    _buildDialogStep(5, 'Check the box next to it'),
                    _buildDialogStep(6, 'Return to this app'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You only need to do this once',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final serverState = context.read<ServerState>();
              await serverState.openAccessibilityPreferences();
              
              if (context.mounted) {
                Navigator.pop(context);
                
                // Show follow-up snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'After granting permission, come back and start the server',
                    ),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Check Now',
                      onPressed: () async {
                        await serverState.checkAccessibilityStatus();
                        if (serverState.hasAccessibilityPermission) {
                          await serverState.startServer();
                        }
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteForPC Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ServerState>(
        builder: (context, serverState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server status card
                _buildStatusCard(serverState),
                const SizedBox(height: 24),

                // QR Code card
                if (serverState.isServerRunning && serverState.serverIpAddress != null)
                  _buildQRCodeCard(serverState),
                
                const SizedBox(height: 24),

                // Connection info
                _buildConnectionInfoCard(serverState),

                const SizedBox(height: 24),

                // Connection logs
                _buildLogsCard(serverState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ServerState serverState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  serverState.isServerRunning ? Icons.check_circle : Icons.cancel,
                  color: serverState.isServerRunning ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serverState.isServerRunning ? 'Server Running' : 'Server Stopped',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (serverState.serverIpAddress != null)
                        Text(
                          '${serverState.serverIpAddress}:${serverState.serverPort}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (!serverState.isServerRunning)
                  FilledButton.icon(
                    onPressed: () async {
                      if (!serverState.hasAccessibilityPermission) {
                        _showAccessibilityDialog();
                      } else {
                        await serverState.startServer();
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      await serverState.stopServer();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  serverState.hasAccessibilityPermission
                      ? Icons.verified_user
                      : Icons.warning,
                  color: serverState.hasAccessibilityPermission
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  serverState.hasAccessibilityPermission
                      ? 'Accessibility: Granted'
                      : 'Accessibility: Not Granted',
                ),
                if (!serverState.hasAccessibilityPermission) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await serverState.openAccessibilityPreferences();
                    },
                    child: const Text('Grant Permission'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(ServerState serverState) {
    final connectionData = {
      'deviceId': serverState.deviceId,
      'ip': serverState.serverIpAddress,
      'port': serverState.serverPort,
      'version': '1.0.0',
    };
    final qrData = base64Encode(utf8.encode(jsonEncode(connectionData)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Scan to Connect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Or manually enter: ${serverState.serverIpAddress}:${serverState.serverPort}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfoCard(ServerState serverState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.devices),
                const SizedBox(width: 8),
                Text(
                  '${serverState.connectedClients} client(s) connected',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(ServerState serverState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connection Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    serverState.clearLogs();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: serverState.connectionLogs.isEmpty
                  ? const Center(
                      child: Text('No logs yet'),
                    )
                  : ListView.builder(
                      itemCount: serverState.connectionLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            serverState.connectionLogs[index],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
