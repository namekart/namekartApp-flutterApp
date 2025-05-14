import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../activity_helpers/FirestoreHelper.dart';
import '../activity_helpers/GlobalFunctions.dart';

class LiveAuctionsListDatabase {
  static Database? _database;
  static final LiveAuctionsListDatabase instance = LiveAuctionsListDatabase._();

  LiveAuctionsListDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'live_list_auctions.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for schema updates
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    List<String> subCollections = await getSubCollectionNames("live_list");
    for (String collection in subCollections) {
      await _createTable(db, collection);
    }
  }

  Future<void> _createTable(Database db, String tableName) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        highlightType TEXT NOT NULL,
        data TEXT NOT NULL,
        datetime TEXT NOT NULL,
        isopened INTEGER NOT NULL
      )
    ''');
    // Create index on datetime for faster queries
    await db.execute(
        'CREATE INDEX idx_${tableName}_datetime ON $tableName(datetime)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      List<String> subCollections = await getSubCollectionNames("live_list");

      // Add indexes to existing tables
      for (var table in subCollections) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_${table}_datetime ON $table(datetime)');
      }
    }
  }
  Future<int> addLiveAuctionList(
      String tableName, String highlightType, String data, String datetime, String isopened) async {

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
        'highlightType': highlightType,
        'data': data,
        'datetime': datetime,
        'isopened': isopened,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace on conflict
    );
  }


  Future<List<Map<String, dynamic>>> getLiveAuctionsList(String tablename) async {
    Database db = await instance.database;
    return await db.query(
      tablename,
      orderBy: 'datetime DESC', // Sort by datetime in descending order
    );
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

  Future<Map<String, dynamic>?> getLast(String tablename) async {
    Database db = await LiveAuctionsListDatabase.instance.database;

    // Query to fetch the last row based on the highest id (most recent).
    List<Map<String, dynamic>> result = await db.query(
      tablename,
      orderBy: 'id DESC', // Sort by id in descending order
      limit: 1, // Limit to 1 row (the last row)
    );

    if (result.isNotEmpty) {
      return result.first; // Return the first row (which is the most recent)
    }

    return null; // Return null if no rows are found
  }

  Future<List<String>> getEmptyTables() async {
    Database db = await instance.database;

    // Step 1: Get all table names in the database
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    List<String> emptyTables = [];

    // Step 2: Check each table to see if it's empty
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'] as String;

      // Query the table to check if it has any rows
      List<Map<String, dynamic>> result = await db.query(tableName, limit: 1);

      // If the table is empty, add it to the list
      if (result.isEmpty) {
        emptyTables.add(tableName);
      }
    }

    // Step 3: Return the list of empty tables
    return emptyTables;
  }

  Future<Map<String, dynamic>> getPaginatedLiveAuctions(String tablename, int startIndex) async {
    Database db = await instance.database;

    // Query to fetch the previous 30 items from the given startIndex
    final List<Map<String, dynamic>> items = await db.query(
      tablename,
      columns: ['id', 'highlightType', 'data', 'datetime', 'isopened'], // Select relevant columns
      where: 'id < ?',
      whereArgs: [startIndex],
      orderBy: 'id DESC', // Fetch older records by sorting in descending order
      limit: 30, // Limit to 30 items
    );

    return {
      'items': items,
      'count': startIndex - items.length, // Remaining count estimation
    };
  }

  Future<int> updateAuction(String tablename, int id,String highlightType, String data,
      String datetime, String isopened) async {
    Database db = await LiveAuctionsListDatabase.instance.database;

    Map<String, dynamic> updatedData = {
      'highlightType':highlightType,
      'data': data,
      'datetime': datetime,
      'isopened': isopened
    };

    return await db
        .update(tablename, updatedData, where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateAllRowsIsOpenedToYes(String tablename) async {
    Database db = await LiveAuctionsListDatabase.instance.database;

    // Create a map with the updated values
    Map<String, dynamic> updatedData = {
      'isopened': 'yes', // or '1' depending on your schema
    };

    // Update all rows in the specified table
    return await db.update(
      tablename,
      updatedData,
      where: '1', // This will match all rows
    );
  }

  Future<int> deleteAuction(String tablename, int id) async {
    Database db = await LiveAuctionsListDatabase.instance.database;

    return await db.delete(tablename, where: 'id=?', whereArgs: [id]);
  }
}
