import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, firebase_auth.FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection('public_profiles');

  firebase_auth.User get _currentUser =>
      _auth.currentUser ??
      (throw StateError('Sign in with Firebase to use chat.'));

  String get currentUserId => _currentUser.uid;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUserId = _currentUser.uid;
    return _publicProfiles.snapshots().map((snapshot) {
      return snapshot.docs
          .where((document) => document.id != currentUserId)
          .map((document) => {...document.data(), 'uid': document.id})
          .toList(growable: false);
    });
  }

  Future<String?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final lookup = await _firestore
        .collection('email_lookup')
        .doc(Uri.encodeComponent(normalizedEmail))
        .get();
    if (!lookup.exists) return null;

    final uid = lookup.data()?['uid'];
    return uid is String && uid.isNotEmpty ? uid : null;
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final sender = _currentUser;
    final trimmedMessage = message.trim();
    if (receiverId.isEmpty || receiverId == sender.uid) {
      throw ArgumentError('Choose another user to start a conversation.');
    }
    if (trimmedMessage.isEmpty) return;

    final chatRoomId = _chatRoomId(sender.uid, receiverId);
    final timestamp = Timestamp.now();
    final messageModel = MessageModel(
      senderId: sender.uid,
      senderEmail: sender.email ?? '',
      receiverId: receiverId,
      message: trimmedMessage,
      timestamp: timestamp,
    );
    final chatRoom = _firestore.collection('chat_rooms').doc(chatRoomId);
    final batch = _firestore.batch();

    batch.set(chatRoom, {
      'participantIds': [sender.uid, receiverId]..sort(),
      'lastMessage': trimmedMessage,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
    batch.set(chatRoom.collection('messages').doc(), messageModel.toMap());
    await batch.commit();
  }

  Future<void> ensureChatRoom(String otherUserId) async {
    final sender = _currentUser;
    if (otherUserId.isEmpty || otherUserId == sender.uid) {
      throw ArgumentError('Choose another user to start a conversation.');
    }

    await _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId(sender.uid, otherUserId))
        .set({
          'participantIds': [sender.uid, otherUserId]..sort(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    final currentUserId = _currentUser.uid;
    if (userId != currentUserId && otherUserId != currentUserId) {
      throw ArgumentError('A conversation must include the signed-in user.');
    }

    final chatRoomId = _chatRoomId(userId, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => MessageModel.fromMap(document.data()))
              .toList(growable: false),
        );
  }

  String _chatRoomId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }
}
