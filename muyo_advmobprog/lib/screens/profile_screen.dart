import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  late Future<User?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _userService.getUserData();
  }

  Future<void> _refreshProfile() async {
    setState(() => _profileFuture = _userService.getUserData());
  }

  Future<void> _editUsername(User user) async {
    final username = await showDialog<String>(
      context: context,
      builder: (_) => _UsernameDialog(username: user.username),
    );
    if (username == null) return;

    try {
      final updatedUser = await _userService.updateUsername(username: username);
      if (mounted) {
        setState(() {
          _profileFuture = Future.value(updatedUser);
        });
      }
    } catch (error) {
      _showMessage('Could not update username: $error');
    }
  }

  Future<void> _changePassword(User user) async {
    final passwords = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _PasswordChangeDialog(),
    );
    if (passwords == null) return;

    try {
      await _userService.resetPasswordFromCurrentPassword(
        email: user.email,
        currentPassword: passwords['current']!,
        newPassword: passwords['new']!,
      );
      _showMessage('Password updated.');
    } catch (error) {
      _showMessage('Could not update password: $error');
    }
  }

  Future<void> _deleteAccount(User user) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(
        requiresPassword: user.loginType == LoginType.firebase,
      ),
    );
    if (password == null) return;

    try {
      await _userService.deleteAccount(
        email: user.email,
        password: password.isEmpty ? null : password,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (error) {
      _showMessage('Could not delete account: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load your profile.'),
                TextButton(
                  onPressed: _refreshProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('No profile data found.'));
        }

        final userId = user.loginType == LoginType.firebase
            ? _userService.currentUser?.uid ?? ''
            : user.id.toString();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: user.image.isEmpty
                    ? null
                    : NetworkImage(user.image),
                child: user.image.isEmpty
                    ? Text(
                        user.fullName.isEmpty
                            ? '?'
                            : user.fullName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.fullName.isEmpty ? user.username : user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              _ProfileRow(
                icon: Icons.alternate_email,
                label: 'Username',
                value: user.username,
                trailing: IconButton(
                  tooltip: 'Update username',
                  onPressed: () => _editUsername(user),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
              if (user.loginType == LoginType.firebase)
                _ProfileRow(
                  icon: Icons.lock_outline,
                  label: 'Password',
                  value: '••••••••',
                  trailing: IconButton(
                    tooltip: 'Change password',
                    onPressed: () => _changePassword(user),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              _ProfileRow(
                icon: Icons.person_outline,
                label: 'First name',
                value: user.firstName,
              ),
              _ProfileRow(
                icon: Icons.person_outline,
                label: 'Last name',
                value: user.lastName,
              ),
              _ProfileRow(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: user.age == 0 ? '' : '${user.age}',
              ),
              _ProfileRow(
                icon: Icons.phone_outlined,
                label: 'Contact number',
                value: user.contactNo,
              ),
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: userId,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _deleteAccount(user),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
      trailing: trailing,
    );
  }
}

class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.username});

  final String username;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.username,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update username'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final username = _controller.text.trim();
            if (username.isNotEmpty) Navigator.pop(context, username);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog();

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your current password'
                  : null,
            ),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
            ),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              validator: (value) => value != _newController.text
                  ? 'Passwords do not match'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'current': _currentController.text,
              'new': _newController.text,
            });
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requiresPassword});

  final bool requiresPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you sure you want to delete this account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This action cannot be undone.'),
          if (widget.requiresPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (widget.requiresPassword && _passwordController.text.isEmpty) {
              return;
            }
            Navigator.pop(context, _passwordController.text);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
