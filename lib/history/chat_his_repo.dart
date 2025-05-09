

import 'chat_his_db.dart';

class SessionInfo {
  final int id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;

  SessionInfo({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
  });

  factory SessionInfo.fromMap(Map<String, dynamic> map) {
    return SessionInfo(
      id: map['id'] as int,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class MessageInfo {
  final int id;
  final int sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isIntro;

  MessageInfo({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isIntro,
  });

  factory MessageInfo.fromMap(Map<String, dynamic> map) {
    return MessageInfo(
      id: map['id'] as int,
      sessionId: map['session_id'] as int,
      text: map['text'] as String,
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isIntro: map['is_intro'] == 1,
    );
  }
}

class ChatHistoryRepository {
  final db = ChatHistoryDb.instance;

  // Session operations
  Future<int> createSession(String fileName, String filePath, DateTime createdAt) async {
    return await db.createSession(fileName, filePath, createdAt);
  }

  Future<List<SessionInfo>> getSessions() async {
    final maps = await db.getSessions();
    return maps.map((map) => SessionInfo.fromMap(map)).toList();
  }

  Future<SessionInfo?> getSession(int id) async {
    final map = await db.getSession(id);
    if (map != null) {
      return SessionInfo.fromMap(map);
    }
    return null;
  }

  Future<int> deleteSession(int id) async {
    return await db.deleteSession(id);
  }

  // Message operations
  Future<int> addMessage(int sessionId, String text, bool isUser, DateTime timestamp, bool isIntro) async {
    return await db.createMessage(sessionId, text, isUser, timestamp, isIntro);
  }

  Future<List<MessageInfo>> getMessagesForSession(int sessionId) async {
    final maps = await db.getMessagesForSession(sessionId);
    return maps.map((map) => MessageInfo.fromMap(map)).toList();
  }
}