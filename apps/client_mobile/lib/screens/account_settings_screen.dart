import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import 'profile_edit_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _changeEmail(BuildContext context) async {
    final authState = context.read<AppAuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final currentEmail = authState.currentUser?.email ?? '';
    final controller = TextEditingController(text: currentEmail);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final ok = await authState.updateEmail(controller.text);
    if (!messenger.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Email update requested. Check your inbox to confirm.'
              : (authState.errorMessage ?? 'Failed to update email.'),
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final authState = context.read<AppAuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();
    bool obscure = true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pass1,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass2,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;

    if (pass1.text.length < 6 || pass1.text != pass2.text) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords must match and be at least 6 characters.')),
      );
      return;
    }

    final ok = await authState.updatePassword(pass1.text);
    if (!messenger.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Password updated.' : (authState.errorMessage ?? 'Failed to update password.')),
      ),
    );
  }

  Future<void> _sendResetEmail(BuildContext context) async {
    final authState = context.read<AppAuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final email = authState.currentUser?.email;

    if (email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No email available for this account.')),
      );
      return;
    }

    final ok = await authState.resetPassword(email);
    if (!messenger.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Password reset email sent.' : (authState.errorMessage ?? 'Failed to send reset email.')),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authState = context.read<AppAuthState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await authState.signOut();
    if (!navigator.mounted) return;

    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account settings'),
      ),
      body: SafeArea(
        child: Consumer<AppAuthState>(
          builder: (context, authState, _) {
            final user = authState.currentUser;
            final email = user?.email;
            final displayName = authState.userProfile?.displayName;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          authState.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                
                // User Profile Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: authState.userProfile?.avatarUrl != null
                              ? NetworkImage(authState.userProfile!.avatarUrl!)
                              : null,
                          child: authState.userProfile?.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        title: Text(authState.userProfile?.displayName ?? email ?? 'Anonymous'),
                        subtitle: Text(user?.isAnonymous == true ? 'Anonymous (LAN only)' : 'Signed in'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: (authState.isLoading || user?.isAnonymous == true)
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileEditScreen(),
                                    ),
                                  );
                                },
                          tooltip: 'Edit profile',
                        ),
                      ),
                      if (authState.userProfile?.phoneNumber != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text('Phone'),
                          subtitle: Text(authState.userProfile!.phoneNumber!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: Text(
                          (displayName != null && displayName.trim().isNotEmpty)
                              ? displayName
                              : (email ?? 'Anonymous'),
                        ),
                        subtitle: Text(user?.isAnonymous == true ? 'Anonymous (LAN only)' : (email ?? 'Signed in')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: authState.isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                                );
                              },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('User ID'),
                        subtitle: Text(user?.id ?? '—'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(email ?? '—'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: (authState.isLoading || user?.isAnonymous == true)
                              ? null
                              : () => _changeEmail(context),
                          tooltip: 'Change email',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outlined),
                        title: const Text('Password'),
                        subtitle: const Text('Update your password'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: authState.isLoading ? null : () => _changePassword(context),
                          tooltip: 'Change password',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.mark_email_read_outlined),
                        title: const Text('Password reset email'),
                        subtitle: const Text('Send a reset link to your email'),
                        trailing: IconButton(
                          icon: const Icon(Icons.send_outlined),
                          onPressed: authState.isLoading ? null : () => _sendResetEmail(context),
                          tooltip: 'Send reset email',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: authState.isLoading ? null : () => _signOut(context),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
