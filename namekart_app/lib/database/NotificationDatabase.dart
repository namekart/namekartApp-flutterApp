import 'dart:ffi';

import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../activity_helpers/FirestoreHelper.dart';
import '../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../activity_helpers/GlobalFunctions.dart';

class NotificationDatabase{
  static Database? _database;

  static final NotificationDatabase instance=NotificationDatabase._();

  NotificationDatabase._();

  Future<Database>get database async{
    if(_database !=null){
      return _database!;
    }

    _database=await _initDatabase();

    return _database!;

  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notifications.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for schema updates
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    List<String> subCollections = await getSubCollectionNames("notifications");
    for (String collection in subCollections) {
      print(collection);
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
    // Create index on datetime for faster queries
    await db.execute(
        'CREATE INDEX idx_${tableName}_datetime ON $tableName(datetime)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      List<String> subCollections = await getSubCollectionNames("notifications");

      // Add indexes to existing tables
      for (var table in subCollections) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_${table}_datetime ON $table(datetime)');
      }
    }
  }




  Future<int> addNotifications(
      String tableName, String notification, String datetime, String isopened) async {

    Database db = await NotificationDatabase.instance.database;

    // Step 1: Check if the table exists
    List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]);

    // Step 2: If table doesn't exist, create it using _createTable
    if (result.isEmpty) {
      await _createTable(db, tableName);
      GlobalProviders.newNotificationTableAddNotifier.notifyNewNotificationTableAdd();
    }

    // Step 3: Insert the notification
    Map<String, dynamic> auction = {
      'data': notification,
      'datetime': datetime,
      'isopened': isopened,
    };

    return await db.insert(tableName, auction);
  }


  Future<List<Map<String, dynamic>>> getNotifications(String tablename) async {
    Database db = await NotificationDatabase.instance.database;
    return await db.query(tablename);
  }

  Future<Map<String, dynamic>?> getLast(String tablename) async {
    Database db = await NotificationDatabase.instance.database;
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

  Future<int> getCountOfUnopenedNotifications(String tablename) async {
    Database db = await NotificationDatabase.instance.database;
    // Count the number of rows where isopened = 'no'
    var result = await db.rawQuery('SELECT COUNT(*) FROM $tablename WHERE isopened = "no"');

    // The result is a list, so we extract the count from the first element of the list
    return Sqflite.firstIntValue(result) ?? 0; // Default to 0 if no rows found
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


    Future<int> updateNotification(String tablename, int id, String notification,
      String datetime, String isopened) async {
    Database db = await NotificationDatabase.instance.database;
    Map<String, dynamic> updatedData = {
      'notification': notification,
      'datetime': datetime,
      'isopened': isopened,
    };

    return await db.update(
        tablename, updatedData, where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateAllRowsIsOpenedToYes(String tablename) async {
    Database db = await NotificationDatabase.instance.database;
    Map<String, dynamic> updatedData = {
      'isopened': 'yes',
    };

    return await db.update(tablename,updatedData,where: '1');
  }

  Future<String> getLatestThreeNotifications(String tablename) async {
    Database db = await NotificationDatabase.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      tablename,
      orderBy: 'id DESC', // Sort by id in descending order
      limit: 3, // Limit to 3 rows (the latest 3)
    );

    if (result.isEmpty) {
      return ''; // Return empty string if no notifications found
    }

    // Join the notifications into a single string separated by '\n'
    return result.map((notification) => notification['notification'] as String).join('\n');
  }


  Future<int> deleteAuction(String tablename, int id) async {
    Database db=await NotificationDatabase.instance.database;
    return await db.delete(tablename,where: 'id=?',whereArgs: [id]);
  }
}