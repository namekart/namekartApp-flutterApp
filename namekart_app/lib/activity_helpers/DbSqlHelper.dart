import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../screens/home_screen/tabs/profile_tab/options_tab/options_buttons/PersonalGroup/PersonalGroup.dart';

class DbSqlHelper {
  static Database? _database;
  static const String _databaseName = 'namekart_app.db';
  static const int _databaseVersion = 1;

  static const String _notificationsDataTable = 'notifications_data';
  static const String _colItemId = 'item_id';
  static const String _colChannel = 'channel';
  static const String _colSubcollection = 'subcollection';
  static const String _colJsonData = 'json_data';

  // --- New: Special key for broad keyword search ---
  static const String anyFieldKeywordSearchKey = '___ANY_FIELD_SEARCH___';

  // Removed _settingsTable, _colSettingKey, _colSettingValue constants

  static Future<void> initDatabase() async {
    if (_database != null) return;
    WidgetsFlutterBinding.ensureInitialized();
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    print("Database initialized and opened: $_databaseName");

    DbAccountHelper.setDatabaseInstance(_database!);
  }

  static Future _onCreate(Database db, int version) async {
    print("Creating database tables...");
    await db.execute('''
      CREATE TABLE $_notificationsDataTable (
          $_colItemId TEXT PRIMARY KEY,
          $_colChannel TEXT NOT NULL,
          $_colSubcollection TEXT NOT NULL,
          $_colJsonData TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notifications_channel_subcollection ON $_notificationsDataTable($_colChannel, $_colSubcollection);');

    // Removed app_settings table creation and initialization
    print("Tables created.");
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Database upgrade from version $oldVersion to $newVersion.");
  }

  static Database get _db {
    if (_database == null) {
      throw Exception('Database not initialized. Call DbSqlHelper.initDatabase() first.');
    }
    return _database!;
  }

  // Helper to safely decode JSON data
  static Map<dynamic, dynamic>? safeJsonDecode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString) as Map<dynamic, dynamic>;
    } on FormatException catch (e) {
      print("JSON Decode Error: $e for string: '$jsonString'");
      return null; // Return null if invalid JSON
    } catch (e) {
      print("Unhandled JSON Decode Error: $e for string: '$jsonString'");
      return null;
    }
  }

  // Helper to standardize read status to 'yes' or 'no' string
  static String _getReadStatusString(dynamic value) {
    if (value == true || value == 'yes') {
      return 'yes';
    }
    // Treat false, 'false', null, or anything else as 'no' for unread status
    return 'no';
  }

  // --- Core Add/Update Data ---
  static Future<String> addData(String path, String id, Map<dynamic, dynamic> info) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'notifications') {
      print(path);
      throw Exception('Invalid path format. Expected "notifications~channel~subcollection".');
    }
    final String channel = parts[1];
    final String subcollection = parts[2];

    String oldReadStatus = 'no'; // Default to 'no' if no existing data or status not found
    final List<Map<String, dynamic>> existing = await _db.query(
      _notificationsDataTable,
      columns: [_colJsonData],
      where: '$_colItemId = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty) {
      final Map<dynamic, dynamic>? oldData = safeJsonDecode(existing.first[_colJsonData]);
      // Standardize the old read status for comparison
      oldReadStatus = _getReadStatusString(oldData?['read']);
    }

    // Standardize the new read status before storing
    final String newReadStatus = _getReadStatusString(info['read']);

    // Create a new map to ensure 'read' is stored as 'yes' or 'no' string
    final Map<String, dynamic> dataToStore = Map<String, dynamic>.from(info);
    dataToStore['read'] = newReadStatus; // THIS IS THE KEY CHANGE

    final Map<String, dynamic> row = {
      _colItemId: id,
      _colChannel: channel,
      _colSubcollection: subcollection,
      _colJsonData: jsonEncode(dataToStore), // Encode the standardized data
    };

    try {
      await _db.insert(
        _notificationsDataTable,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Added/Updated data for $id in $channel~$subcollection (SQL)");

      // Removed all read count update logic here.
      // If you need global counts, implement them using getReadCount in your UI layer.

      return id;
    } catch (e) {
      print("Error adding/updating data to $_notificationsDataTable: $e");
      rethrow;
    }
  }

  static Future<String> updateData(String path, String id, Map<dynamic, dynamic> info) async {
    return await addData(path, id, info);
  }

  // --- Read Data ---
  static Future<dynamic> read(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty || parts[0] != 'notifications') {
      return {};
    }

    if (parts.length == 1 && parts[0] == 'notifications') {
      final Map<dynamic, dynamic> channelsMap = {};
      final List<Map<String, dynamic>> channelRows = await _db.query(
        _notificationsDataTable,
        columns: ['DISTINCT $_colChannel'],
      );
      for (final row in channelRows) {
        final channel = row[_colChannel] as String;
        final subcollectionRows = await _db.query(
          _notificationsDataTable,
          columns: ['DISTINCT $_colSubcollection'],
          where: '$_colChannel = ?',
          whereArgs: [channel],
        );
        final Map<dynamic, dynamic> subcollectionsMap = {};
        for (final subRow in subcollectionRows) {
          subcollectionsMap[subRow[_colSubcollection]] = {};
        }
        channelsMap[channel] = subcollectionsMap;
      }
      return channelsMap;
    }
    else if (parts.length == 2 && parts[0] == 'notifications') {
      final String channel = parts[1];
      final Map<dynamic, dynamic> subcollectionsMap = {};
      final List<Map<String, dynamic>> subcollectionRows = await _db.query(
        _notificationsDataTable,
        columns: ['DISTINCT $_colSubcollection'],
        where: '$_colChannel = ?',
        whereArgs: [channel],
      );
      for (final row in subcollectionRows) {
        subcollectionsMap[row[_colSubcollection]] = {};
      }
      return subcollectionsMap;
    }
    else if (parts.length >= 3 && parts[0] == 'notifications') {
      final String channel = parts[1];
      final String subcollection = parts[2];
      final Map<dynamic, dynamic> itemsMap = {};
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        where: '$_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [channel, subcollection],
        orderBy: 'json_extract($_colJsonData, "\$.datetime_id") DESC',
      );
      for (final row in results) {
        final String itemId = row[_colItemId] as String;
        final Map<dynamic, dynamic>? itemData = safeJsonDecode(row[_colJsonData]); // Use safe decode
        if (itemData != null) {
          itemsMap[itemId] = itemData;
        } else {
          print("Skipping malformed JSON for item $itemId in $channel~$subcollection");
        }
      }
      return itemsMap;
    }

    return null;
  }

  // --- Get Read Count (Count of items with 'read' status 'no') ---
  static Future<int> getReadCount(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty || parts[0] != 'notifications') {
      // If path does not start with "notifications", invalid.
      return 0;
    }

    String whereClause = 'json_extract($_colJsonData, "\$.read") = ?';
    List<dynamic> whereArgs = ['no'];

    // Build additional WHERE conditions based on the number of parts
    if (parts.length >= 2) {
      whereClause += ' AND $_colChannel = ?';
      whereArgs.add(parts[1]);
    }
    if (parts.length >= 3) {
      whereClause += ' AND $_colSubcollection = ?';
      whereArgs.add(parts[2]);
    }
    if (parts.length >= 4) {
      whereClause += ' AND $_colItemId = ?';
      whereArgs.add(parts[3]);
    }

    try {
      final result = await _db.query(
        _notificationsDataTable,
        columns: ['COUNT(*)'],
        where: whereClause,
        whereArgs: whereArgs,
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print("Error getting read count for $path: $e");
      return 0;
    }
  }
  // --- Delete Data ---
  static Future<void> delete(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      // Deleting all notifications
      await _db.delete(_notificationsDataTable);
      // Removed settings updates for global counts
      print("All notification data cleared.");
      return;
    }

    if (parts.length >= 4 && parts[0] == 'notifications') {
      final String channel = parts[1];
      final String subcollection = parts[2];
      final String itemId = parts[3];

      // Although the homeReadCount is removed, keeping this check
      // might be useful if you re-introduce similar logic elsewhere.
      // However, it no longer directly affects the app_settings table.
      bool wasUnread = false;
      final List<Map<String, dynamic>> existing = await _db.query(
        _notificationsDataTable,
        columns: [_colJsonData],
        where: '$_colItemId = ? AND $_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [itemId, channel, subcollection],
      );
      if (existing.isNotEmpty) {
        final Map<dynamic, dynamic>? itemData = safeJsonDecode(existing.first[_colJsonData]);
        if (_getReadStatusString(itemData?['read']) == 'no') { // Use helper for consistency
          wasUnread = true;
        }
      }

      final deletedCount = await _db.delete(
        _notificationsDataTable,
        where: '$_colItemId = ? AND $_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [itemId, channel, subcollection],
      );
      // Removed settings updates for global counts
      print("Deleted item $itemId from $path");
      return;
    }
    else if (parts.length == 3 && parts[0] == 'notifications') {
      final String channel = parts[1];
      final String subcollection = parts[2];

      // Use the new getReadCount for accurate unread count before deletion
      // This count is for informational logging or to be used by calling code,
      // not to update internal settings table.
      final int unreadCountBefore = await getReadCount(path);

      final deletedCount = await _db.delete(
        _notificationsDataTable,
        where: '$_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [channel, subcollection],
      );
      // Removed settings updates for global counts
      print("Deleted all items in $path (was unread: $unreadCountBefore)");
      return;
    }
    else if (parts.length == 2 && parts[0] == 'notifications') {
      final String channel = parts[1];

      // Use the new getReadCount for accurate unread count before deletion
      final int unreadCountBefore = await getReadCount(path);

      final deletedCount = await _db.delete(
        _notificationsDataTable,
        where: '$_colChannel = ?',
        whereArgs: [channel],
      );
      // Removed settings updates for global counts
      print("Deleted all items in channel $path (was unread: $unreadCountBefore)");
      return;
    }

    throw Exception('Unsupported delete path: $path');
  }

  static Future<void> removeDataKeepingLatestTwoDaysPerPath(List<String> paths) async {
    bool dataChanged = false;
    final db = _db;

    for (final path in paths) {
      final parts = path.split('~').where((p) => p.isNotEmpty).toList();
      if (parts.length < 3 || parts[0] != 'notifications') {
        print("Skipping invalid path for cleanup: $path");
        continue;
      }

      final String channel = parts[1];
      final String subcollection = parts[2];

      try {
        final List<Map<String, dynamic>> allItems = await db.query(
          _notificationsDataTable,
          columns: [_colItemId, _colJsonData],
          where: '$_colChannel = ? AND $_colSubcollection = ?',
          whereArgs: [channel, subcollection],
        );

        final Set<String> daysInThisPath = {};
        final Map<String, List<String>> itemIdsByDay = {};

        for (final itemRow in allItems) {
          final String itemId = itemRow[_colItemId] as String;
          final Map<dynamic, dynamic>? itemData = safeJsonDecode(itemRow[_colJsonData]);
          final String? datetimeIdStr = itemData?['datetime_id']?.toString(); // Use null-aware

          if (datetimeIdStr != null) {
            final DateTime? dt = DateTime.tryParse(datetimeIdStr);
            if (dt != null) {
              final dayStr = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
              daysInThisPath.add(dayStr);
              itemIdsByDay.putIfAbsent(dayStr, () => []).add(itemId);
            }
          }
        }

        if (daysInThisPath.isEmpty) {
          print("ℹ️ No data with datetime_id under $path for cleanup.");
          continue;
        }

        final sortedDays = daysInThisPath.toList()..sort((a, b) => b.compareTo(a));
        final keepDays = <String>{};
        if (sortedDays.isNotEmpty) {
          keepDays.add(sortedDays[0]);
          if (sortedDays.length > 1) {
            keepDays.add(sortedDays[1]);
          }
        }

        final List<String> itemIdsToRemove = [];
        for (final dayStr in sortedDays) {
          if (!keepDays.contains(dayStr)) {
            itemIdsToRemove.addAll(itemIdsByDay[dayStr] ?? []);
          }
        }

        if (itemIdsToRemove.isNotEmpty) {
          // You can still get unread items being removed for logging or other external use
          final int unreadItemsBeingRemoved = await db.query(
            _notificationsDataTable,
            columns: ['COUNT(*)'],
            where: '$_colItemId IN (${List.filled(itemIdsToRemove.length, '?').join(',')}) AND json_extract($_colJsonData, "\$.read") = ?',
            whereArgs: [...itemIdsToRemove, 'no'],
          ).then((results) => Sqflite.firstIntValue(results) ?? 0);

          await _db.transaction((txn) async {
            await txn.delete(
              _notificationsDataTable,
              where: '$_colItemId IN (${List.filled(itemIdsToRemove.length, '?').join(',')})',
              whereArgs: itemIdsToRemove,
            );
          });
          dataChanged = true;
          print("✅ Cleaned $path, kept days: $keepDays, removed ${itemIdsToRemove.length} items (of which $unreadItemsBeingRemoved were unread).");
        } else {
          print("ℹ️ No old data to remove in $path.");
        }

      } catch (e) {
        print("Error cleaning data for path $path: $e");
      }
    }
    if (dataChanged) {
      print("✅ Completed cleaning all paths that had changes.");
    } else {
      print("ℹ️ No data needed to be removed in any path.");
    }
  }

  // --- GetById ---
  static Future<Map<dynamic, dynamic>?> getById(String path, String id) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'notifications') return null;

    final String channel = parts[1];
    final String subcollection = parts[2];

    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        where: '$_colItemId = ? AND $_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [id, channel, subcollection],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return safeJsonDecode(results.first[_colJsonData]); // Use safe decode
      }
      return null;
    } catch (e) {
      print("Error getting item by ID $id for path $path: $e");
      return null;
    }
  }

  // --- getKeys ---
  static Future<List> getKeys(String path) async {
    final Map<dynamic, dynamic> data = await read(path);
    if (data is Map<dynamic, dynamic>) {
      return data.keys.toList();
    }
    return [];
  }

  // --- getLast ---
  static Future<Map?> getLast(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'notifications') return null;

    final String channel = parts[1];
    final String subcollection = parts[2];

    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        where: '$_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [channel, subcollection],
        orderBy: 'json_extract($_colJsonData, "\$.datetime_id") DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        return safeJsonDecode(results.first[_colJsonData]); // Use safe decode
      }
      return null;
    } catch (e) {
      print("Error getting last item for $path: $e");
      return null;
    }
  }

  // --- getDataForDate ---
  static Future<List<Map<dynamic, dynamic>>> getDataForDate(String path, String targetDate) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'notifications') return [];

    final String channel = parts[1];
    final String subcollection = parts[2];

    final int startOfDay = DateTime.parse(targetDate).millisecondsSinceEpoch;
    final int endOfDay = DateTime.parse(targetDate).add(const Duration(days: 1)).millisecondsSinceEpoch - 1;

    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        where: '$_colChannel = ? AND $_colSubcollection = ? AND json_extract($_colJsonData, "\$.datetime_id") >= ? AND json_extract($_colJsonData, "\$.datetime_id") <= ?',
        whereArgs: [channel, subcollection, startOfDay.toString(), endOfDay.toString()],
        orderBy: 'json_extract($_colJsonData, "\$.datetime_id") DESC',
      );
      return results.map((row) {
        final Map<dynamic, dynamic>? itemData = safeJsonDecode(row[_colJsonData]);
        return itemData ?? {}; // Return empty map if decode fails
      }).where((item) => item.isNotEmpty).toList(); // Filter out nulls/empty maps
    } catch (e) {
      print("Error getting data for date $targetDate for $path: $e");
      return [];
    }
  }

  // --- getFullData ---
  static Future<List<Map<dynamic, dynamic>>> getFullData(String path) async {
    final dynamic data = await read(path);
    if (data is! Map<dynamic, dynamic>) return [];

    final matchedItems = <Map<dynamic, dynamic>>[];
    data.forEach((key, value) {
      if (value is Map && value.containsKey('datetime_id')) {
        matchedItems.add(Map<dynamic, dynamic>.from(value));
      }
    });

    matchedItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['datetime_id'].toString()) ?? DateTime(0);
      final bDate = DateTime.tryParse(b['datetime_id'].toString()) ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    return matchedItems;
  }

  // --- getFirstDate ---
  static Future<DateTime?> getFirstDate(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'notifications') return null;

    final String channel = parts[1];
    final String subcollection = parts[2];

    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        columns: ['MIN(json_extract($_colJsonData, "\$.datetime_id")) AS min_datetime_id'],
        where: '$_colChannel = ? AND $_colSubcollection = ?',
        whereArgs: [channel, subcollection],
      );

      if (results.isNotEmpty && results.first['min_datetime_id'] != null) {
        return DateTime.tryParse(results.first['min_datetime_id'].toString());
      }
      return null;
    } catch (e) {
      print("Error getting first date for $path: $e");
      return null;
    }
  }

  // --- getPaginatedAuctions ---
  static Future<Map<dynamic, dynamic>> getPaginatedAuctions(String path, int startIndex, {int limit = 30}) async {
    print("WARNING: getPaginatedAuctions requires dedicated SQL table/logic for auctions.");
    return {
      'items': [],
      'count': startIndex,
    };
  }

  // --- searchInDataList ---
  static Future<List<Map<dynamic, dynamic>>> searchInDataList(List<Map<dynamic, dynamic>> dataList, String query) async {
    final lowerQuery = query.toLowerCase().trim();
    return dataList.where((entry) {
      return entry.values.any((value) => value.toString().toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Removed getHomeScreenReadCount and getChannelScreenReadCount

  // Removed _getSetting, _setSetting, _incrementSetting, _decrementSetting internal helpers

  // --- `mark` functions ---
  static Future<void> markAsRead(String fullPath) async {
    final parts = fullPath.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 4) {
      throw Exception('Invalid path for markAsRead. Expected "notifications~channel~subcollection~item_id".');
    }
    final String itemId = parts[3];
    await _updateReadStatusInternal(fullPath, itemId: itemId, readStatus: true);
  }

  static Future<void> markAllAsRead(String partialPath) async {
    await _updateReadStatusInternal(partialPath, readStatus: true);
  }

  static Future<void> markEverythingAsRead() async {
    await _db.rawUpdate(
      'UPDATE $_notificationsDataTable SET $_colJsonData = json_set($_colJsonData, "\$.read", "yes") WHERE json_extract($_colJsonData, "\$.read") = ?',
      ['no'],
    );
    // Removed _setSetting calls
    print("All notifications marked as read globally in SQL.");
  }

  // --- INTERNAL HELPER FUNCTIONS ---
  static Future<void> _updateReadStatusInternal(String path, {String? itemId, required bool readStatus}) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.length < 2 || parts[0] != 'notifications') {
      throw Exception('Invalid path for _updateReadStatusInternal.');
    }

    final String channel = parts[1];
    String? subcollection;
    if (parts.length >= 3) {
      subcollection = parts[2];
    }

    await _db.transaction((txn) async {
      String whereClause = '';
      List<dynamic> whereArgs = [];
      // Removed affectedChannelId as it's only used for settings table updates

      if (itemId != null) {
        whereClause = '$_colItemId = ?';
        whereArgs = [itemId];
      } else if (subcollection != null && subcollection.isNotEmpty) {
        whereClause = '$_colChannel = ? AND $_colSubcollection = ?';
        whereArgs = [channel, subcollection];
      } else { // Mark all in channel
        whereClause = '$_colChannel = ?';
        whereArgs = [channel];
      }

      await txn.rawUpdate(
        'UPDATE $_notificationsDataTable SET $_colJsonData = json_set($_colJsonData, "\$.read", ?) WHERE $whereClause',
        [readStatus ? 'yes' : 'no', ...whereArgs],
      );

      // Removed all _incrementSetting and _decrementSetting calls
    });
  }

  static Future<List<String>> searchPathsContaining(String query) async {
    final lowerQuery = '%${query.toLowerCase().trim()}%';
    final List<String> paths = [];

    List<Map<String, dynamic>> channelResults = await _db.query(
      _notificationsDataTable,
      columns: ['DISTINCT $_colChannel'],
      where: '$_colChannel LIKE ?',
      whereArgs: [lowerQuery],
    );
    for (final row in channelResults) {
      paths.add('notifications~${row[_colChannel]}');
    }

    List<Map<String, dynamic>> subcollectionResults = await _db.query(
      _notificationsDataTable,
      columns: ['$_colChannel', '$_colSubcollection'],
      distinct: true,
      where: '$_colSubcollection LIKE ?',
      whereArgs: [lowerQuery],
    );
    for (final row in subcollectionResults) {
      paths.add('notifications~${row[_colChannel]}~${row[_colSubcollection]}');
    }

    return paths.toSet().toList();
  }

  static Future<List<String>> getCategoryPathsOnly() async {
    final List<String> paths = [];

    final channelResults = await _db.query(
      _notificationsDataTable,
      columns: ['DISTINCT $_colChannel'],
      orderBy: '$_colChannel ASC',
    );
    for (final row in channelResults) {
      paths.add('notifications~${row[_colChannel]}');
    }

    final subcollectionResults = await _db.query(
      _notificationsDataTable,
      columns: ['$_colChannel', '$_colSubcollection'],
      distinct: true,
      orderBy: '$_colChannel ASC, $_colSubcollection ASC',
    );
    for (final row in subcollectionResults) {
      paths.add('notifications~${row[_colChannel]}~${row[_colSubcollection]}');
    }
    return paths;
  }

  static Future<List<String>> getAllAvailablePaths({int maxDepth = 4}) async {
    return await getCategoryPathsOnly();
  }

  static Future<List<String>> getRingAlarmPaths() async {
    final List<String> ringAlarmPaths = [];
    final results = await _db.query(
      _notificationsDataTable,
      where: "json_extract($_colJsonData, '\$.ringAlarm') = 'true' OR json_extract($_colJsonData, '\$.ringAlarm') = 1",
    );

    for (final row in results) {
      final channel = row[_colChannel] as String;
      final subcollection = row[_colSubcollection] as String;
      final itemId = row[_colItemId] as String;
      ringAlarmPaths.add('notifications~$channel~$subcollection~$itemId~ringAlarm');
    }
    return ringAlarmPaths;
  }

  static Future<void> disableRingAlarm(String fullPath) async {
    final parts = fullPath.split('~').where((p) => p.isNotEmpty).toList();
    if (parts.length < 4) return;

    final String itemId = parts[3];

    final List<Map<String, dynamic>> existing = await _db.query(
      _notificationsDataTable,
      columns: [_colJsonData],
      where: '$_colItemId = ?',
      whereArgs: [itemId],
    );

    if (existing.isNotEmpty) {
      final Map<dynamic, dynamic>? itemData = safeJsonDecode(existing.first[_colJsonData]);
      if (itemData != null) { // Only proceed if JSON was valid
        itemData['ringAlarm'] = false;
        await _db.update(
          _notificationsDataTable,
          {_colJsonData: jsonEncode(itemData)},
          where: '$_colItemId = ?',
          whereArgs: [itemId],
        );
      } else {
        print("Warning: Could not disable ring alarm for item $itemId due to malformed JSON data.");
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getWatchlist() async {
    final List<Map<String, dynamic>> watchlist = [];
    final results = await _db.query(
      _notificationsDataTable,
      where: "json_extract($_colJsonData, '\$.actionsDone') LIKE '%\"Watch\"%'",
    );

    for (final row in results) {
      final Map<dynamic, dynamic>? itemData = safeJsonDecode(row[_colJsonData].toString());
      if (itemData != null) { // Only add if JSON was valid
        final channel = row[_colChannel] as String;
        final subcollection = row[_colSubcollection] as String;

        final String watchlistPath = 'notifications~$channel~$subcollection';
        watchlist.add({
          'path': watchlistPath,
          'itemData': itemData,
        });
      } else {
        print("Warning: Skipping malformed JSON for watchlist item.");
      }
    }
    return watchlist;
  }


  static Future<List<Map<String, dynamic>>> getSampleDataBlocks({int limit = 50}) async {
    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _notificationsDataTable,
        columns: [_colJsonData],
        orderBy: 'json_extract($_colJsonData, "\$.datetime") DESC',
        limit: limit,
      );

      final List<Map<String, dynamic>> dataBlocks = [];
      for (final row in results) {
        final Map<dynamic, dynamic>? itemData = safeJsonDecode(row[_colJsonData]);
        if (itemData != null && itemData.containsKey('data') && itemData['data'] is Map) {
          dataBlocks.add(Map<String, dynamic>.from(itemData['data']!));
        }
      }
      return dataBlocks;
    } catch (e) {
      print("Error getting sample data blocks: $e");
      return [];
    }
  }

  // --- getFilteredNotifications (Modified) ---
  // Helper to extract a numeric value for a given category from a string like "Age:6 | EST:180"
  static double? _extractNumericValueFromEmbeddedString(String? sourceString, String categoryName) {
    if (sourceString == null || sourceString.isEmpty || categoryName.isEmpty) {
      print("DEBUG: _extractNumericValueFromEmbeddedString: Invalid input. sourceString: $sourceString, categoryName: $categoryName");
      return null;
    }

    // --- CRITICAL FIX START ---
    final String lowerSourceString = sourceString.toLowerCase(); // Convert source to lowercase
    final String lowerCategoryName = categoryName.toLowerCase(); // Convert category to lowercase
    final String searchPattern = '$lowerCategoryName:'; // Build lowercase pattern
    // --- CRITICAL FIX END ---

    final int startIndex = lowerSourceString.indexOf(searchPattern); // Search in lowercase

    if (startIndex == -1) {
      print("DEBUG: _extractNumericValueFromEmbeddedString: Category '$categoryName' not found (case-insensitive) in '$sourceString'.");
      return null; // Category not found
    }

    // The indices and substrings should now operate on the ORIGINAL sourceString
    // to preserve case and content of the actual value, but calculation from lowerCase `startIndex`
    int valueStart = startIndex + searchPattern.length;

    // Adjust valueStart based on the ORIGINAL string's content
    // We need to find the actual value starting point in the original string.
    // The `startIndex` is derived from the lowercase search, so `valueStart`
    // will be an index into the lowercase string. We need to apply this
    // offset to the original string.

    // Calculate effective start index in original string:
    // Find the actual position of the category in the original string (case-sensitive)
    final int actualCategoryStartIndex = sourceString.toLowerCase().indexOf(lowerCategoryName + ":");
    if (actualCategoryStartIndex == -1) { // Fallback, though unlikely given prior check
      return null;
    }
    int actualValueStartIndex = actualCategoryStartIndex + categoryName.length + 1; // +1 for the colon

    // Check for an optional space after the colon in the ORIGINAL string
    if (actualValueStartIndex < sourceString.length && sourceString[actualValueStartIndex] == ' ') {
      actualValueStartIndex++;
    }

    int valueEnd = sourceString.indexOf('|', actualValueStartIndex);
    String valueString;

    if (valueEnd == -1) {
      valueString = sourceString.substring(actualValueStartIndex);
    } else {
      valueString = sourceString.substring(actualValueStartIndex, valueEnd);
    }

    final parsedValue = double.tryParse(valueString.trim());
    print("DEBUG: _extractNumericValueFromEmbeddedString: Source: '$sourceString', Category: '$categoryName', Extracted String: '${valueString.trim()}', Parsed Double: $parsedValue");
    return parsedValue;
  }

  // ... (getFilteredNotifications - no changes needed here for this specific issue) ...


  // --- REVISED: getFilteredNotificationsByEmbeddedNumericValue ---
  static Future<List<Map<dynamic, dynamic>>> getFilteredNotificationsByEmbeddedNumericValue({
    required String categoryName,
    required NumericComparisonOperator operator,
    required double numericValue,
    List<String> hxFields = const ['\$.data.h1', '\$.data.h2', '\$.data.h3', '\$.data.h4', '\$.data.h5'],
    String orderBy = 'json_extract(json_data, "\$.datetime_id") DESC',
    int? limit,
    int? offset,
  }) async {
    print("DEBUG: getFilteredNotificationsByEmbeddedNumericValue called for category: $categoryName, operator: $operator, value: $numericValue");

    final String jsonDataCol = _colJsonData;
    final List<String> orClauses = [];
    final List<Object?> args = [];

    for (final hxPath in hxFields) {
      orClauses.add('json_extract($jsonDataCol, "$hxPath") LIKE ?');
      args.add('%${categoryName}:%'); // Broad search for "Category:" pattern
    }

    if (orClauses.isEmpty) {
      print("DEBUG: getFilteredNotificationsByEmbeddedNumericValue: No hxFields to search, returning empty.");
      return [];
    }

    final String whereClause = '(${orClauses.join(' OR ')})';
    print("DEBUG: SQL whereClause for broad search: $whereClause with args: $args");


    final List<Map<String, dynamic>> rawResults = await queryNotificationsByJson(
      whereClause: whereClause,
      whereArgs: args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    print("DEBUG: Raw results from DB (count: ${rawResults.length}): $rawResults");


    final List<Map<dynamic, dynamic>> filteredDartResults = [];
    for (final row in rawResults) {
      final String? jsonDataString = row[_colJsonData] as String?;
      final Map<dynamic, dynamic>? decodedJson = safeJsonDecode(jsonDataString);

      if (decodedJson == null || decodedJson['data'] == null || decodedJson['data'] is! Map) {
        print("DEBUG: Skipping row (no valid JSON data or 'data' field): $row");
        continue;
      }

      bool matchesFilter = false;
      for (final hxPath in hxFields) {
        final String hxKey = hxPath.split('.').last; // Extracts 'h1', 'h2', etc.
        final String? hxValue = decodedJson['data'][hxKey] as String?;

        print("DEBUG: Processing row for hxPath: $hxPath, hxKey: $hxKey, hxValue: '$hxValue'");

        if (hxValue != null) {
          final double? extractedNum = _extractNumericValueFromEmbeddedString(hxValue, categoryName);

          if (extractedNum != null) {
            bool comparisonResult = false;
            switch (operator) {
              case NumericComparisonOperator.greaterThan:
                comparisonResult = extractedNum > numericValue;
                break;
              case NumericComparisonOperator.lessThan:
                comparisonResult = extractedNum < numericValue;
                break;
              case NumericComparisonOperator.equals:
                comparisonResult = extractedNum == numericValue;
                break;
              case NumericComparisonOperator.greaterThanOrEqual:
                comparisonResult = extractedNum >= numericValue;
                break;
              case NumericComparisonOperator.lessThanOrEqual:
                comparisonResult = extractedNum <= numericValue;
                break;
            }
            print("DEBUG: Comparison: Extracted '$extractedNum' $operator '$numericValue' -> $comparisonResult");
            if (comparisonResult) {
              matchesFilter = true;
              break;
            }
          }
        }
      }

      if (matchesFilter) {
        String channel = row?['channel']?.toString() ?? 'unknown_channel';
        String subchannel = row?['subcollection']?.toString() ?? 'unknown_subchannel';
        String constructedPath = 'notifications~$channel~$subchannel';
        filteredDartResults.add({
          _colItemId: row[_colItemId],
          'path': constructedPath,
          ...decodedJson,
        });
        print("DEBUG: Row MATCHES filter, added to results. Item ID: ${row[_colItemId]}");
      } else {
        print("DEBUG: Row does NOT match filter. Item ID: ${row[_colItemId]}");
      }
    }
    print("DEBUG: Final Dart-filtered results count: ${filteredDartResults.length}");
    return filteredDartResults;
  }


  // --- Original getFilteredNotifications (Unchanged, it handles general cases) ---
  static Future<List<Map<dynamic, dynamic>>> getFilteredNotifications({
    required QueryCondition condition,
    String orderBy = 'json_extract(json_data, "\$.datetime_id") DESC',
    int? limit,
    int? offset,
  }) async {
    String whereClause;
    List<Object?> args = [];

    final String jsonDataCol = _colJsonData;
    final String fullJsonPath = condition.jsonPath;

    if (fullJsonPath == DbSqlHelper.anyFieldKeywordSearchKey) {
      final List<String> orClauses = [];
      final String likeValue = '%${condition.value}%';

      // 1. Search directly in common top-level fields
      final List<String> topLevelTextPaths = [
        '\$.device_notification[0].title', '\$.device_notification[0].message', '\$.device_notification[0].topic',
        '\$.read'
      ];
      for (final path in topLevelTextPaths) {
        orClauses.add('json_extract($jsonDataCol, "$path") LIKE ?');
        args.add(likeValue);
      }

      // 2. Search in 'data' hX fields
      for (int i = 1; i <= 5; i++) {
        final hXPath = '\$.data.h$i';
        orClauses.add('json_extract($jsonDataCol, "$hXPath") LIKE ?');
        args.add(likeValue);

        // Also check if the 'category:value' pattern exists within hX fields
        if (condition.value.isNotEmpty && condition.categoryName != null && condition.categoryName!.isNotEmpty) {
          orClauses.add('json_extract($jsonDataCol, "$hXPath") LIKE ?');
          args.add('%${condition.categoryName!}:%${condition.value}%');
          orClauses.add('json_extract($jsonDataCol, "$hXPath") LIKE ?');
          args.add('%${condition.categoryName!}: %${condition.value}%');
        }
      }

      // 3. Search in uiButtons button_text
      orClauses.add('json_extract($jsonDataCol, "\$.uiButtons[*].button_text") LIKE ?');
      args.add(likeValue);

      whereClause = '(${orClauses.join(' OR ')})';

    } else if (fullJsonPath.isEmpty) {
      throw Exception('JSON Path cannot be empty for filtering.');
    } else {
      // Standard JSON path-based filtering
      switch (condition.condition) {
        case FilterCondition.isEmpty:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") IS NULL OR json_extract($jsonDataCol, "$fullJsonPath") = ?';
          args.add('');
          break;
        case FilterCondition.isNotEmpty:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") IS NOT NULL AND json_extract($jsonDataCol, "$fullJsonPath") != ?';
          args.add('');
          break;
        case FilterCondition.isNumber:
          whereClause = 'typeof(json_extract($jsonDataCol, "$fullJsonPath")) IN (\'real\', \'integer\')';
          break;
        case FilterCondition.isNotNumber:
          whereClause = 'typeof(json_extract($jsonDataCol, "$fullJsonPath")) NOT IN (\'real\', \'integer\') AND json_extract($jsonDataCol, "$fullJsonPath") IS NOT NULL';
          break;
        case FilterCondition.greaterThan:
          whereClause = 'CAST(json_extract($jsonDataCol, "$fullJsonPath") AS REAL) > ?';
          args.add(double.parse(condition.value));
          break;
        case FilterCondition.lessThan:
          whereClause = 'CAST(json_extract($jsonDataCol, "$fullJsonPath") AS REAL) < ?';
          args.add(double.parse(condition.value));
          break;
        case FilterCondition.endsWith:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") LIKE ?';
          args.add('%${condition.value}');
          break;
        case FilterCondition.startsWith:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") LIKE ?';
          args.add('${condition.value}%');
          break;
        case FilterCondition.contains:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") LIKE ?';
          args.add('%${condition.value}%');
          break;
        case FilterCondition.regexMatches:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") REGEXP ?';
          args.add(condition.value);
          break;
        case FilterCondition.equalsCaseSensitive:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") = ?';
          args.add(condition.value);
          break;
        case FilterCondition.equalsCaseInsensitive:
          whereClause = 'json_extract($jsonDataCol, "$fullJsonPath") COLLATE NOCASE = ?';
          args.add(condition.value);
          break;
        default:
          throw Exception("Unsupported filter condition: ${condition.condition}");
      }
    }

    final List<Map<String, dynamic>> rawResults = await queryNotificationsByJson(
      whereClause: whereClause,
      whereArgs: args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return rawResults.map((row) {
      final String? jsonData = row[_colJsonData] as String?;
      final Map<dynamic, dynamic>? decodedJson = safeJsonDecode(jsonData);
      String channel = row?['channel']?.toString() ?? 'unknown_channel';
      String subchannel = row?['subcollection']?.toString() ?? 'unknown_subchannel';
      String constructedPath = 'notifications~$channel~$subchannel';

      return {
        _colItemId: row[_colItemId],
        'path': constructedPath,
        ...decodedJson ?? {},
      };
    }).toList();
  }

  // --- queryNotificationsByJson (Unchanged) ---
  static Future<List<Map<String, dynamic>>> queryNotificationsByJson({
    required String whereClause,
    List<Object?>? whereArgs,
    String orderBy = '',
    int? limit,
    int? offset,
  }) async {
    String sql = 'SELECT * FROM $_notificationsDataTable WHERE $whereClause';

    if (orderBy.isNotEmpty) {
      sql += ' ORDER BY $orderBy';
    }
    if (limit != null) {
      sql += ' LIMIT $limit';
    }
    if (offset != null) {
      sql += ' OFFSET $offset';
    }

    try {
      final List<Map<String, dynamic>> results = await _db.rawQuery(sql, whereArgs);
      print("Executed raw queryNotificationsByJson: $sql with args $whereArgs");
      return results;
    } catch (e) {
      print("Error executing raw queryNotificationsByJson: $sql with args $whereArgs, Error: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> doQueryOnDatabase(
      String sql, [
        List<Object?>? arguments,
      ]) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized. Call DbSqlHelper.initDatabase() first.');
      }
      print("Executing raw SQL query: '$sql' with arguments: $arguments");
      final List<Map<String, dynamic>> results = await _db.rawQuery(sql, arguments);
      print("Query executed successfully. Rows returned: ${results.length}");
      return results;
    } catch (e) {
      print("Error executing custom SQL query: $e");
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }
}