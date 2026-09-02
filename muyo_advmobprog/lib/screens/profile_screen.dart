import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: UserService().getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) return const Center(child: Text('No profile data found.'));

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: user.image.isEmpty ? null : NetworkImage(user.image),
                child: user.image.isEmpty ? Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
              ),
              const SizedBox(height: 12),
              Center(child: Text(user.fullName, style: Theme.of(context).textTheme.titleLarge)),
              Center(child: Text('@${user.username}')),
              const SizedBox(height: 28),
              _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
              _ProfileRow(icon: Icons.wc_outlined, label: 'Gender', value: user.gender),
              _ProfileRow(icon: Icons.badge_outlined, label: 'User ID', value: '${user.id}'),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await UserService().logout();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
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

  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
