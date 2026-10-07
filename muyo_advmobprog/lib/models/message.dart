import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  const MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final timestamp = map['timestamp'];
    return MessageModel(
      senderId: map['senderId'] as String? ?? '',
      senderEmail: map['senderEmail'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: timestamp is Timestamp ? timestamp : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderEmail': senderEmail,
    'receiverId': receiverId,
    'message': message,
    'timestamp': timestamp,
  };
}
