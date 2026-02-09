import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/server_state.dart';
import '../state/auth_state.dart' as app_state;
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _portController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final serverState = context.read<ServerState>();
    _portController.text = serverState.serverPort.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check accessibility status when screen comes into focus
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    final serverState = context.read<ServerState>();
    await serverState.checkAccessibilityStatus();
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ServerState>(
        builder: (context, serverState, child) {
          return Consumer<app_state.AuthState>(
            builder: (context, authState, child) {
              return ListView(
                children: [
                  // Account Section (if authenticated)
                  if (authState.isAuthenticated) ...[
                    _buildSectionHeader('Account'),
                    _buildAccountInfo(authState),
                    _buildChangePasswordTile(authState),
                    _buildSignOutTile(authState),
                    const Divider(),
                  ] else ...[
                    _buildSectionHeader('Account'),
                    _buildSignInTile(),
                    const Divider(),
                  ],
                  
                  // Server Settings Section
                  _buildSectionHeader('Server Settings'),
                  _buildPortSetting(serverState),
                  _buildDeviceIdSetting(serverState),
                  
                  const Divider(),
                  
                  // Permissions Section
                  _buildSectionHeader('Permissions'),
                  _buildAccessibilitySetting(serverState),
                  
                  const Divider(),
                  
                  // About Section
                  _buildSectionHeader('About'),
                  _buildAboutTile(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAccountInfo(app_state.AuthState authState) {
    final profile = authState.profile;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profile?.avatarUrl != null
            ? NetworkImage(profile!.avatarUrl!)
            : null,
        child: profile?.avatarUrl == null
            ? Text(
                (profile?.displayName ?? authState.user?.email ?? 'U')[0].toUpperCase(),
              )
            : null,
      ),
      title: Text(profile?.displayName ?? authState.user?.email ?? 'User'),
      subtitle: Text(authState.user?.email ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showEditProfileDialog(authState),
      ),
    );
  }

  Widget _buildChangePasswordTile(app_state.AuthState authState) {
    return ListTile(
      leading: const Icon(Icons.lock_reset),
      title: const Text('Change Password'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showChangePasswordDialog(authState),
    );
  }

  Widget _buildSignOutTile(app_state.AuthState authState) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await authState.signOut();
        }
      },
    );
  }

  Widget _buildSignInTile() {
    return ListTile(
      leading: const Icon(Icons.login),
      title: const Text('Sign In / Sign Up'),
      subtitle: const Text('Create an account to sync your settings'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(app_state.AuthState authState) {
    final displayNameController = TextEditingController(
      text: authState.profile?.displayName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await authState.updateProfile(
                displayName: displayNameController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Profile updated successfully'
                          : 'Failed to update profile',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(app_state.AuthState authState) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await authState.changePassword(
                passwordController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password changed successfully'
                          : 'Failed to change password',
                    ),
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPortSetting(ServerState serverState) {
    return ListTile(
      leading: const Icon(Icons.network_check),
      title: const Text('Server Port'),
      subtitle: _isEditing
          ? TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                hintText: 'Enter port number',
                helperText: 'Valid range: 1024-65535',
              ),
              onSubmitted: (value) => _savePort(serverState),
            )
          : Text('Port ${serverState.serverPort}'),
      trailing: _isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _savePort(serverState),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _portController.text = serverState.serverPort.toString();
                    });
                  },
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: serverState.isServerRunning
                  ? null
                  : () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
            ),
    );
  }

  void _savePort(ServerState serverState) {
    final port = int.tryParse(_portController.text);
    if (port == null || port < 1024 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid port number. Please enter a value between 1024 and 65535.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    serverState.updatePort(port);
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Port updated to $port. Restart the server to apply changes.'),
      ),
    );
  }

  Widget _buildDeviceIdSetting(ServerState serverState) {
    return ListTile(
      leading: const Icon(Icons.fingerprint),
      title: const Text('Device ID'),
      subtitle: Text(
        serverState.deviceId,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        tooltip: 'Copy Device ID',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: serverState.deviceId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device ID copied to clipboard')),
          );
        },
      ),
    );
  }

  Widget _buildAccessibilitySetting(ServerState serverState) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  serverState.hasAccessibilityPermission
                      ? Icons.verified_user
                      : Icons.warning,
                  color: serverState.hasAccessibilityPermission
                      ? Colors.green
                      : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility Access',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serverState.hasAccessibilityPermission
                            ? 'Granted - RemoteForPC can control input devices'
                            : 'Required - Permission needed to control mouse and keyboard',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!serverState.hasAccessibilityPermission) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Follow these steps to grant permission:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _buildStep(1, 'Click "Open Settings" button below'),
              _buildStep(2, 'Click the lock icon 🔒 at the bottom left'),
              _buildStep(3, 'Enter your Mac password'),
              _buildStep(4, 'Find "server_desktop" in the list'),
              _buildStep(5, 'Check the box next to the app'),
              _buildStep(6, 'Click the refresh button below'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await serverState.openAccessibilityPreferences();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Status',
                    onPressed: () async {
                      await serverState.checkAccessibilityStatus();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              serverState.hasAccessibilityPermission
                                  ? '✓ Permission granted!'
                                  : 'Permission not granted yet. Follow the steps above.',
                            ),
                            backgroundColor: serverState.hasAccessibilityPermission
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('All set! You can now use RemoteForPC.'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Status',
                    onPressed: () async {
                      await serverState.checkAccessibilityStatus();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About RemoteForPC'),
      subtitle: const Text('Version 1.0.0'),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'RemoteForPC Server',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.desktop_mac, size: 48),
          children: [
            const Text(
              'Control your computer remotely from your phone.\n\n'
              'Features:\n'
              '• Mouse control\n'
              '• Keyboard input\n'
              '• Secure WebSocket connection\n'
              '• Multi-screen support',
            ),
          ],
        );
      },
    );
  }
}
