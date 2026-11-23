import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'ndax_ai.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<ChatMessage>> getMessages() async {
    final db = await database;
    final rows = await db.query('messages', orderBy: 'id ASC');
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> addMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
  }

  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }
}
