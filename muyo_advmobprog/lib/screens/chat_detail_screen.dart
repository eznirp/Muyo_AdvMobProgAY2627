import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.tappedUser});

  final Map<String, dynamic> tappedUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  late final String _currentUserId;
  late final String _otherUserId;
  late final Future<void> _roomFuture;
  late final Stream<List<MessageModel>> _messagesStream;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _chatService.currentUserId;
    _otherUserId = widget.tappedUser['uid'] as String? ?? '';
    _roomFuture = _chatService.ensureChatRoom(_otherUserId);
    _messagesStream = _chatService.getMessages(_currentUserId, _otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _title {
    final name = [
      widget.tappedUser['firstName'],
      widget.tappedUser['lastName'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return name.isNotEmpty
        ? name
        : (widget.tappedUser['username'] as String? ?? 'Chat');
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(_otherUserId, text);
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send message: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title),
            if ((widget.tappedUser['username'] as String? ?? '').isNotEmpty)
              Text(
                '@${widget.tappedUser['username']}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<void>(
                future: _roomFuture,
                builder: (context, roomSnapshot) {
                  if (roomSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (roomSnapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Could not open this conversation. Check your Firestore rules.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<List<MessageModel>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Could not load messages.'),
                        );
                      }
                      final messages = snapshot.data ?? const [];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Send a message to start the conversation.',
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMine = message.senderId == _currentUserId;
                          final colors = Theme.of(context).colorScheme;
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? colors.primaryContainer
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(message.message),
                                  const SizedBox(height: 4),
                                  Text(
                                    TimeOfDay.fromDateTime(
                                      message.timestamp.toDate(),
                                    ).format(context),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
