import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../state/server_state.dart';
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
        title: const Text('Accessibility Permission Required'),
        content: const Text(
          'RemoteForPC needs accessibility permissions to control your mouse and keyboard.\n\n'
          'Click "Open Settings" to grant permission in System Preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final serverState = context.read<ServerState>();
              await serverState.openAccessibilityPreferences();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
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
              // TODO: Navigate to settings
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
