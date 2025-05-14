import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:namekart_app/storageClasses/Auctions.dart';

import '../activity_helpers/FirestoreHelper.dart';
import '../activity_helpers/GlobalFunctions.dart';

class LiveAuctionsDatabase {
  static Database? _database;
  static final LiveAuctionsDatabase instance = LiveAuctionsDatabase._();

  LiveAuctionsDatabase._();

  Future<Database> get database async {
    if (_database == null || !_database!.isOpen) {
      print('Database was closed or uninitialized. Reopening...');
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'live_auctions.db');
    print('Opening database at: $path');

    try {
      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
      );
      await _database!.execute('CREATE TABLE IF NOT EXISTS test_table (id INTEGER)');
      await _database!.execute('DROP TABLE test_table');
      return _database!;
    } catch (e) {
      print('Error opening database: $e');
      await deleteDatabase(path);
      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
      );
      return _database!;
    }
  }

  // Public method to reset the database
  Future<void> resetDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    print('Database reset. It will be reinitialized on next access.');
  }


  Future<void> _onCreate(Database db, int version) async {
    List<String> subCollections = await getSubCollectionNames("live");
    for (String collection in subCollections) {
      await _createTable(db, collection);
    }
  }

  Future<void> _createTable(Database db, String tableName) async {
    await db.execute('''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        datetime TEXT NOT NULL,
        isopened INTEGER NOT NULL
    )
    ''');
    await db.execute('CREATE INDEX idx_${tableName}_datetime ON $tableName(datetime)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      List<String> subCollections = await getSubCollectionNames("live");

      // Add indexes to existing tables
      for (var table in subCollections) {        await db.execute('CREATE INDEX IF NOT EXISTS idx_${table}_datetime ON $table(datetime)');
      }
    }
  }

  Future<int> addLiveAuction(String tableName, String data, String datetime, String isopened) async {
    try {
      Database db = await instance.database;

      // Step 1: Check if the table exists
      List<Map<String, dynamic>> result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]);

      // Step 2: If table doesn't exist, create it
      if (result.isEmpty) {
        await _createTable(db, tableName);
      }

      // Step 3: Insert the auction data
      return await db.insert(
        tableName,
        {
          'data': data,
          'datetime': datetime,
          'isopened': isopened,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Replace on conflict
      );
    } catch (e) {
      print('Error adding live auction: $e');
      return -1; // Return -1 on error
    }
  }


  Future<List<Map<String, dynamic>>> getLiveAuctionsData(String tablename, {int limit = 50, int offset = 0}) async {
    try {
      Database db = await instance.database;
      if (!db.isOpen) {
        print('Database was closed. Reopening...');
        db = await instance.database;
      }

      final result = await db.query(
        tablename,
        limit: limit,
        offset: offset,
        orderBy: 'datetime DESC',
      );
      return result;
    } catch (e) {
      print('Error fetching live auctions data: $e');
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> getLiveAuctionsDataForToday(String tablename) async {
    Database db = await instance.database;
    final today = DateTime.now();
    final formattedToday = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    return await db.query(
      tablename,
      where: "DATE(datetime) = ?",
      whereArgs: [formattedToday],
      orderBy: "datetime DESC",
    );
  }

  Future<Map<String, dynamic>> getPaginatedAuctions(String tablename, int startIndex) async {
    Database db = await instance.database;

    // Query to fetch the previous 30 items from the given startIndex
    final List<Map<String, dynamic>> items = await db.query(
      tablename,
      columns: ['id', '*'], // Select the id and all other columns
      where: 'id < ?',
      whereArgs: [startIndex],
      orderBy: 'id DESC', // Get previous items by sorting in descending order
      limit: 30, // Limit to 30 items
    );
    return {
      'items': items,
      'count': startIndex-items.length,
    };
  }


  Future<Map<String, dynamic>?> getLast(String tablename) async {
    try {
      Database db = await instance.database;
      final result = await db.query(
        tablename,
        orderBy: 'datetime DESC',
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Latest item: ${result.first}');
        return result.first;
      } else {
        print('No items found in $tablename');
        return null;
      }
    } catch (e) {
      print('Error fetching last item: $e');
      return null;
    }
  }

  Future<void> cleanupOldData(String tablename, {int daysToKeep = 7}) async {
    Database db = await instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      tablename,
      where: 'datetime < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<int> getTotalCount(String tablename) async {
    Database db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tablename');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getAuctionById(String id, String tablename) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(tablename, where: 'id=?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<String>> getEmptyTables() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    List<String> emptyTables = [];
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'] as String;
      List<Map<String, dynamic>> result = await db.query(tableName, limit: 1);
      if (result.isEmpty) emptyTables.add(tableName);
    }
    return emptyTables;
  }

  Future<int> updateAuction(String tablename, int id, String data, String datetime, String isopened) async {
    Database db = await instance.database;
    Map<String, dynamic> updatedData = {'data': data, 'datetime': datetime, 'isopened': isopened};
    return await db.update(tablename, updatedData, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteAuction(String tablename, int id) async {
    Database db = await instance.database;
    return await db.delete(tablename, where: 'id=?', whereArgs: [id]);
  }
}