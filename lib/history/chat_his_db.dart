import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatHistoryDb {
  static final ChatHistoryDb instance = ChatHistoryDb._init();
  static Database? _database;

  ChatHistoryDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      is_user INTEGER NOT NULL,
      timestamp TEXT NOT NULL,
      is_intro INTEGER NOT NULL,
      FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
    )
    ''');
  }

  // Sessions operations
  Future<int> createSession(String fileName, String filePath, DateTime createdAt) async {
    final db = await instance.database;

    final data = {
      'file_name': fileName,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };

    return await db.insert('sessions', data);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await instance.database;
    return await db.query(
      'sessions',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getSession(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> deleteSession(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Messages operations
  Future<int> createMessage(int sessionId, String text, bool isUser, DateTime timestamp, bool isIntro) async {
    final db = await instance.database;

    final data = {
      'session_id': sessionId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'is_intro': isIntro ? 1 : 0,
    };

    return await db.insert('messages', data);
  }

  Future<List<Map<String, dynamic>>> getMessagesForSession(int sessionId) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}