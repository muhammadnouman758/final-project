import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

// Domain models
class ChatSession {
  final int? id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? summary;

  ChatSession({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.summary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_updated_at': lastUpdatedAt.millisecondsSinceEpoch,
      'summary': summary,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      fileName: map['file_name'],
      filePath: map['file_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(map['last_updated_at']),
      summary: map['summary'],
    );
  }
}

class ChatMessage {
  final int? id;
  final int sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isIntro;

  ChatMessage({
    this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isIntro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_intro': isIntro ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['session_id'],
      text: map['text'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isIntro: map['is_intro'] == 1,
    );
  }
}

// Database provider
class ChatDatabaseProvider {
  static final ChatDatabaseProvider _instance = ChatDatabaseProvider._internal();
  static Database? _database;

  factory ChatDatabaseProvider() => _instance;

  ChatDatabaseProvider._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pdf_chat_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Chat sessions table
    await db.execute(
      '''
      CREATE TABLE chat_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        summary TEXT
      )
      ''',
    );

    // Chat messages table
    await db.execute(
      '''
      CREATE TABLE chat_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        is_intro INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
      ''',
    );
  }

  // Session operations
  Future<int> insertSession(ChatSession session) async {
    final db = await database;
    return await db.insert('chat_sessions', session.toMap());
  }

  Future<int> updateSession(ChatSession session) async {
    final db = await database;
    return await db.update(
      'chat_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      orderBy: 'last_updated_at DESC',
    );

    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  Future<ChatSession?> getSession(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChatSession.fromMap(maps.first);
    }
    return null;
  }

  // Message operations
  Future<int> insertMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ChatMessage>> getMessagesForSession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('chat_messages');
    await db.delete('chat_sessions');
  }
}
