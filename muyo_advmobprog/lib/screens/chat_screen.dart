import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  final _userService = UserService();
  late final Future<User?> _currentUserFuture;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _userService.getUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> user) {
    final name = [
      user['firstName'],
      user['lastName'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return name.isNotEmpty ? name : (user['username'] as String? ?? 'User');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: SafeArea(
        child: FutureBuilder<User?>(
          future: _currentUserFuture,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userSnapshot.hasError) {
              return const Center(child: Text('Could not load your account.'));
            }
            final currentUser = userSnapshot.data;
            if (currentUser == null ||
                currentUser.loginType != LoginType.firebase) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Chat is available when you are signed in with a Firebase account.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchText = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search people',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Could not load chat users. Check your connection and Firestore rules.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final query = _searchText.trim().toLowerCase();
                      final users = (snapshot.data ?? const [])
                          .where((user) {
                            if (query.isEmpty) return true;
                            return _displayName(
                                  user,
                                ).toLowerCase().contains(query) ||
                                (user['username'] as String? ?? '')
                                    .toLowerCase()
                                    .contains(query);
                          })
                          .toList(growable: false);

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            query.isEmpty
                                ? 'No other Firebase users yet.'
                                : 'No users match your search.',
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final name = _displayName(user);
                          final username = user['username'] as String? ?? '';
                          final image = user['image'] as String? ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: image.isEmpty
                                  ? null
                                  : NetworkImage(image),
                              child: image.isEmpty
                                  ? Text(name.characters.first.toUpperCase())
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: Text(
                              username.isEmpty ? 'Tap to chat' : '@$username',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ChatDetailScreen(tappedUser: user),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
