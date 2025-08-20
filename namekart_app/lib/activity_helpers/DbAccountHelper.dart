import 'dart:convert';
import 'package:flutter/cupertino.dart'; // For WidgetsFlutterBinding.ensureInitialized
import 'package:flutter/foundation.dart'; // For listEquals
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // For Directory

class DbAccountHelper {
  static Database? _database;
  static const String _accountDetailsTable = 'account_user_details';
  static const String _colUsername = 'username';
  static const String _colJsonData = 'json_data';

  // Private flag to track if the table has been initialized
  static bool _isTableInitialized = false;

  // --- Set the shared database instance (Called by DbSqlHelper) ---
  static void setDatabaseInstance(Database db) {
    _database = db;
    // When database instance is set, we can mark table as not yet initialized
    // to ensure _ensureTableExists is run when the first operation happens.
    _isTableInitialized = false;
  }

  // --- Helper to get the database instance ---
  static Database get _db {
    if (_database == null) {
      throw Exception('Database not initialized. Ensure DbSqlHelper.initDatabase() is called first and sets the shared database instance.');
    }
    return _database!;
  }

  // --- Ensure Table Exists ---
  // This private method will be called by all public methods of DbAccountHelper
  static Future<void> _ensureTableExists() async {
    if (_isTableInitialized && _database != null) {
      return; // Table is already ensured and database is open
    }
    // Perform table creation if it doesn't exist
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $_accountDetailsTable (
          $_colUsername TEXT PRIMARY KEY,
          $_colJsonData TEXT NOT NULL
      )
    ''');
    print("Table '$_accountDetailsTable' ensured to exist by _ensureTableExists().");
    _isTableInitialized = true; // Mark as initialized
  }


  // --- Add/Update Account Data ---
  static Future<void> addData(String path, String id, Map<dynamic, dynamic> info) async {
    await _ensureTableExists(); // Ensure table exists before operation

    const expectedPathParts = ['account', 'user', 'details'];
    final actualPathParts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (actualPathParts.length != expectedPathParts.length ||
        !listEquals(actualPathParts, expectedPathParts)) {
      throw Exception('Invalid path for addData. Expected "account~user~details".');
    }

    final Map<String, dynamic> row = {
      _colUsername: id,
      _colJsonData: jsonEncode(info),
    };

    try {
      await _db.insert(
        _accountDetailsTable,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Added/Updated account data for user: $id");
    } catch (e) {
      print("Error adding/updating account data to $_accountDetailsTable: $e");
      rethrow;
    }
  }

  // --- Read Account Data ---
  static Future<Map<dynamic, dynamic>?> readData(String path, String id) async {
    await _ensureTableExists(); // Ensure table exists before operation

    const expectedPathParts = ['account', 'user', 'details'];
    final actualPathParts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (actualPathParts.length != expectedPathParts.length ||
        !listEquals(actualPathParts, expectedPathParts)) {
      throw Exception('Invalid path for readData. Expected "account~user~details".');
    }

    try {
      final List<Map<String, dynamic>> results = await _db.query(
        _accountDetailsTable,
        where: '$_colUsername = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return jsonDecode(results.first[_colJsonData]) as Map<dynamic, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error reading account data for user $id: $e");
      return null;
    }
  }

  // --- Delete Account Data ---
  static Future<void> deleteData(String path, {String? username}) async {
    await _ensureTableExists(); // Ensure table exists before operation

    const expectedPathParts = ['account', 'user', 'details'];
    final actualPathParts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (actualPathParts.length != expectedPathParts.length ||
        !listEquals(actualPathParts, expectedPathParts)) {
      // It's crucial to throw an exception here because continuing with an invalid path
      // might lead to unexpected behavior or accidental table-wide deletion.
      throw Exception('Invalid path for deleteData. Expected "account~user~details".');
    }

    try {
      if (username != null && username.isNotEmpty) {
        await _db.delete(
          _accountDetailsTable,
          where: '$_colUsername = ?',
          whereArgs: [username],
        );
        print("Deleted account data for user: $username");
      } else {
        await _db.delete(_accountDetailsTable);
        print("Deleted all data from '$_accountDetailsTable' table.");
      }
    } catch (e) {
      print("Error deleting account data: $e");
      rethrow;
    }
  }

  // --- Check if data is present ---
  static Future<bool> isDataPresent(String path, {String? username}) async {
    await _ensureTableExists(); // Ensure table exists before operation

    const expectedPathParts = ['account', 'user', 'details'];
    final actualPathParts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (actualPathParts.length != expectedPathParts.length ||
        !listEquals(actualPathParts, expectedPathParts)) {
      throw Exception('Invalid path for isDataPresent. Expected "account~user~details".');
    }

    try {
      List<Map<String, dynamic>> results;
      if (username != null && username.isNotEmpty) {
        results = await _db.query(
          _accountDetailsTable,
          columns: [_colUsername],
          where: '$_colUsername = ?',
          whereArgs: [username],
          limit: 1,
        );
      } else {
        results = await _db.query(
          _accountDetailsTable,
          columns: [_colUsername],
          limit: 1,
        );
      }
      return results.isNotEmpty;
    } catch (e) {
      print("Error checking data presence in $_accountDetailsTable: $e");
      return false;
    }
  }


  static Future<void> addStar(String accountPath, String userId, String starSubPath, String starId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for addStar. Expected "account~user~details".');
    }

    try {
      // 1. Read existing data for the user
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{}; // Initialize as empty if no data or wrong type

      // Ensure 'star' key exists and is a Map
      Map<String, dynamic> stars = (currentJsonData['star'] != null && currentJsonData['star'] is Map<String, dynamic>)
          ? currentJsonData['star'] as Map<String, dynamic>
          : <String, dynamic>{};

      // Ensure the specific starSubPath key exists and is a List
      List<dynamic> starIdsList = (stars[starSubPath] != null && stars[starSubPath] is List<dynamic>)
          ? stars[starSubPath] as List<dynamic>
          : <dynamic>[];

      // Add the starId if it's not already present
      if (!starIdsList.contains(starId)) {
        starIdsList.add(starId);
        stars[starSubPath] = starIdsList; // Update the list in the stars map
        currentJsonData['star'] = stars; // Update the stars map in the main data

        // 2. Update the entire json_data for the user
        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Added star ID '$starId' to '$starSubPath' for user: $userId");
      } else {
        print("Star ID '$starId' already exists in '$starSubPath' for user: $userId. No action taken.");
      }
    } catch (e) {
      print("Error adding star for user $userId, path $starSubPath, ID $starId: $e");
      rethrow;
    }
  }

  // --- NEW: Delete a specific star ID from a star path ---
  static Future<void> deleteStar(String accountPath, String userId, String starSubPath, String starId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for deleteStar. Expected "account~user~details".');
    }

    try {
      // 1. Read existing data for the user
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      // Check if 'star' key exists and is a Map
      Map<String, dynamic> stars = (currentJsonData['star'] != null && currentJsonData['star'] is Map<String, dynamic>)
          ? currentJsonData['star'] as Map<String, dynamic>
          : <String, dynamic>{};

      // Check if the specific starSubPath key exists and is a List
      List<dynamic> starIdsList = (stars[starSubPath] != null && stars[starSubPath] is List<dynamic>)
          ? stars[starSubPath] as List<dynamic>
          : <dynamic>[];

      // Remove the starId if it exists
      final bool removed = starIdsList.remove(starId);

      if (removed) {
        stars[starSubPath] = starIdsList; // Update the list in the stars map
        if (starIdsList.isEmpty) {
          stars.remove(starSubPath); // Remove the sub-path key if the list becomes empty
        }
        if (stars.isEmpty) {
          currentJsonData.remove('star'); // Remove the 'star' key if it becomes empty
        } else {
          currentJsonData['star'] = stars; // Update the stars map in the main data
        }


        // 2. Update the entire json_data for the user
        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Deleted star ID '$starId' from '$starSubPath' for user: $userId");
      } else {
        print("Star ID '$starId' not found in '$starSubPath' for user: $userId. No action taken.");
      }
    } catch (e) {
      print("Error deleting star for user $userId, path $starSubPath, ID $starId: $e");
      rethrow;
    }
  }

  // --- NEW: Get all star IDs for a specific star path, or all stars if starSubPath is null ---
  static Future<Map<String, dynamic>?> getStar(String accountPath, String userId, {String? starSubPath}) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for getStar. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      Map<String, dynamic> stars = (currentJsonData['star'] != null && currentJsonData['star'] is Map<String, dynamic>)
          ? currentJsonData['star'] as Map<String, dynamic>
          : <String, dynamic>{};

      if (starSubPath != null && starSubPath.isNotEmpty) {
        // Return only the list for the specified starSubPath
        if (stars.containsKey(starSubPath) && stars[starSubPath] is List<dynamic>) {
          print("Retrieved stars for '$starSubPath' for user: $userId");
          return {starSubPath: stars[starSubPath]}; // Return as a map for consistency
        } else {
          print("No stars found for '$starSubPath' for user: $userId.");
          return {}; // Return empty map if specific sub-path not found
        }
      } else {
        // Return the entire 'star' map
        print("Retrieved all stars for user: $userId");
        return stars; // Returns the full star map (could be empty if no stars)
      }
    } catch (e) {
      print("Error getting star data for user $userId, path $starSubPath: $e");
      return null; // Indicates a retrieval error
    }
  }

  static Future<bool> isStarred(String accountPath, String userId, String starSubPath, String starId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for isStarred. Expected "account~user~details".');
    }

    try {
      // Directly use getStar to fetch the specific list, then check for existence
      Map<String, dynamic>? result = await getStar(accountPath, userId, starSubPath: starSubPath);

      if (result != null && result.containsKey(starSubPath) && result[starSubPath] is List<dynamic>) {
        List<dynamic> starIdsList = result[starSubPath] as List<dynamic>;
        bool found = starIdsList.contains(starId);
        print("Checked if star ID '$starId' is present in '$starSubPath' for user: $userId - $found");
        return found;
      } else {
        // If the sub-path or list doesn't exist, it's not starred
        print("Star sub-path '$starSubPath' not found or is not a list for user: $userId. Not starred.");
        return false;
      }
    } catch (e) {
      print("Error checking if starred for user $userId, path $starSubPath, ID $starId: $e");
      return false; // Return false on error
    }
  }

  static Future<void> addNotification(String accountPath, String userId, String notificationSubPath, String notificationId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for addNotification. Expected "account~user~details".');
    }

    try {
      // 1. Read existing data for the user
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{}; // Initialize as empty if no data or wrong type

      // Ensure 'notifications' key exists and is a Map
      Map<String, dynamic> notifications = (currentJsonData['notifications'] != null && currentJsonData['notifications'] is Map<String, dynamic>)
          ? currentJsonData['notifications'] as Map<String, dynamic>
          : <String, dynamic>{};

      // Ensure the specific notificationSubPath key exists and is a List
      List<dynamic> notificationIdsList = (notifications[notificationSubPath] != null && notifications[notificationSubPath] is List<dynamic>)
          ? notifications[notificationSubPath] as List<dynamic>
          : <dynamic>[];

      // Add the notificationId if it's not already present
      if (!notificationIdsList.contains(notificationId)) {
        notificationIdsList.add(notificationId);
        notifications[notificationSubPath] = notificationIdsList; // Update the list in the notifications map
        currentJsonData['notifications'] = notifications; // Update the notifications map in the main data

        // 2. Update the entire json_data for the user
        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Added notification ID '$notificationId' to '$notificationSubPath' for user: $userId");
      } else {
        print("Notification ID '$notificationId' already exists in '$notificationSubPath' for user: $userId. No action taken.");
      }
    } catch (e) {
      print("Error adding notification for user $userId, path $notificationSubPath, ID $notificationId: $e");
      rethrow;
    }
  }

  // --- NEW: Delete a specific notification ID from a notification path ---
  static Future<void> deleteNotification(String accountPath, String userId, String notificationSubPath, String notificationId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for deleteNotification. Expected "account~user~details".');
    }

    try {
      // 1. Read existing data for the user
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      // Check if 'notifications' key exists and is a Map
      Map<String, dynamic> notifications = (currentJsonData['notifications'] != null && currentJsonData['notifications'] is Map<String, dynamic>)
          ? currentJsonData['notifications'] as Map<String, dynamic>
          : <String, dynamic>{};

      // Check if the specific notificationSubPath key exists and is a List
      List<dynamic> notificationIdsList = (notifications[notificationSubPath] != null && notifications[notificationSubPath] is List<dynamic>)
          ? notifications[notificationSubPath] as List<dynamic>
          : <dynamic>[];

      // Remove the notificationId if it exists
      final bool removed = notificationIdsList.remove(notificationId);

      if (removed) {
        notifications[notificationSubPath] = notificationIdsList; // Update the list in the notifications map
        if (notificationIdsList.isEmpty) {
          notifications.remove(notificationSubPath); // Remove the sub-path key if the list becomes empty
        }
        if (notifications.isEmpty) {
          currentJsonData.remove('notifications'); // Remove the 'notifications' key if it becomes empty
        } else {
          currentJsonData['notifications'] = notifications; // Update the notifications map in the main data
        }

        // 2. Update the entire json_data for the user
        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Deleted notification ID '$notificationId' from '$notificationSubPath' for user: $userId");
      } else {
        print("Notification ID '$notificationId' not found in '$notificationSubPath' for user: $userId. No action taken.");
      }
    } catch (e) {
      print("Error deleting notification for user $userId, path $notificationSubPath, ID $notificationId: $e");
      rethrow;
    }
  }

  // --- NEW: Get all notification IDs for a specific notification path, or all notifications if notificationSubPath is null ---
  static Future<Map<String, dynamic>?> getNotification(String accountPath, String userId, {String? notificationSubPath}) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts = accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception('Invalid accountPath for getNotification. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData = (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      Map<String, dynamic> notifications = (currentJsonData['notifications'] != null && currentJsonData['notifications'] is Map<String, dynamic>)
          ? currentJsonData['notifications'] as Map<String, dynamic>
          : <String, dynamic>{};

      if (notificationSubPath != null && notificationSubPath.isNotEmpty) {
        // Return only the list for the specified notificationSubPath
        if (notifications.containsKey(notificationSubPath) && notifications[notificationSubPath] is List<dynamic>) {
          print("Retrieved notifications for '$notificationSubPath' for user: $userId");
          return {notificationSubPath: notifications[notificationSubPath]}; // Return as a map for consistency
        } else {
          print("No notifications found for '$notificationSubPath' for user: $userId.");
          return {}; // Return empty map if specific sub-path not found
        }
      } else {
        // Return the entire 'notifications' map
        print("Retrieved all notifications for user: $userId");
        return notifications; // Returns the full notifications map (could be empty if no notifications)
      }
    } catch (e) {
      print("Error getting notification data for user $userId, path $notificationSubPath: $e");
      return null; // Indicates a retrieval error
    }
  }


  // --- NEW: Add a personal group to the 'personal_group' list ---
  static Future<void> addPersonalGroup(String accountPath, String userId,
      Map<String, dynamic> groupData) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts =
    accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception(
          'Invalid accountPath for addPersonalGroup. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData =
      (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      // Ensure 'personal_group' key exists and is a List
      List<dynamic> personalGroups = (currentJsonData['personal_group'] != null &&
          currentJsonData['personal_group'] is List<dynamic>)
          ? currentJsonData['personal_group'] as List<dynamic>
          : <dynamic>[];

      // Check if a group with the same name already exists to prevent duplicates
      // Assuming 'name' is the unique identifier for a group within the list
      bool groupExists = personalGroups.any((group) =>
      group is Map<String, dynamic> && group['name'] == groupData['name']);

      if (!groupExists) {
        personalGroups.add(groupData);
        currentJsonData['personal_group'] = personalGroups;

        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Added personal group '${groupData['name']}' for user: $userId");
      } else {
        print(
            "Personal group with name '${groupData['name']}' already exists for user: $userId. No action taken.");
      }
    } catch (e) {
      print(
          "Error adding personal group for user $userId, group data $groupData: $e");
      rethrow;
    }
  }

  // --- NEW: Remove a personal group from the 'personal_group' list ---
  static Future<void> removePersonalGroup(
      String accountPath, String userId, String groupName) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts =
    accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception(
          'Invalid accountPath for removePersonalGroup. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData =
      (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      List<dynamic> personalGroups = (currentJsonData['personal_group'] != null &&
          currentJsonData['personal_group'] is List<dynamic>)
          ? currentJsonData['personal_group'] as List<dynamic>
          : <dynamic>[];

      // Find and remove the group by its name
      final int initialLength = personalGroups.length;
      personalGroups.removeWhere(
              (group) => group is Map<String, dynamic> && group['name'] == groupName);

      if (personalGroups.length < initialLength) {
        // Only update if a group was actually removed
        if (personalGroups.isEmpty) {
          currentJsonData.remove(
              'personal_group'); // Remove key if list becomes empty
        } else {
          currentJsonData['personal_group'] = personalGroups;
        }

        final Map<String, dynamic> row = {
          _colUsername: userId,
          _colJsonData: jsonEncode(currentJsonData),
        };

        await _db.insert(
          _accountDetailsTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Removed personal group '$groupName' for user: $userId");
      } else {
        print(
            "Personal group with name '$groupName' not found for user: $userId. No action taken.");
      }
    } catch (e) {
      print(
          "Error removing personal group for user $userId, group name $groupName: $e");
      rethrow;
    }
  }

  // --- NEW: Get all personal groups for a specific user ---
  static Future<List<Map<String, dynamic>>?> getPersonalGroup(
      String accountPath, String userId) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts =
    accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception(
          'Invalid accountPath for getPersonalGroup. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData =
      (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      if (currentJsonData.containsKey('personal_group') &&
          currentJsonData['personal_group'] is List<dynamic>) {
        final List<dynamic> rawList = currentJsonData['personal_group'];
        // Cast each item to Map<String, dynamic> to ensure type safety
        final List<Map<String, dynamic>> personalGroups = rawList
            .whereType<Map<String, dynamic>>() // Filter out non-map items
            .toList();

        print("Retrieved ${personalGroups.length} personal groups for user: $userId");
        return personalGroups;
      } else {
        print("No personal groups found for user: $userId.");
        return []; // Return an empty list if no 'personal_group' key or it's not a list
      }
    } catch (e) {
      print("Error getting personal groups for user $userId: $e");
      return null; // Indicates a retrieval error
    }
  }


  static Future<void> updateQuicknotes(
      String accountPath, String userId, List<Map<String, dynamic>> quicknotes) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts =
    accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception(
          'Invalid accountPath for updateQuicknotes. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData =
      (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      if (quicknotes.isEmpty) {
        // If the provided list is empty, remove the 'quicknote' field entirely
        currentJsonData.remove('quicknote');
        print("Removed 'quicknote' field as the provided list was empty for user: $userId");
      } else {
        // Otherwise, replace the 'quicknote' field with the new list
        currentJsonData['quicknote'] = quicknotes;
        print("Updated quicknotes list for user: $userId");
      }

      final Map<String, dynamic> row = {
        _colUsername: userId,
        _colJsonData: jsonEncode(currentJsonData),
      };

      await _db.insert(
        _accountDetailsTable,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error updating quicknotes for user $userId: $e");
      rethrow;
    }
  }

// --- NEW: Get quicknote data ---
  static Future<List<Map<String, dynamic>>?> getQuicknote(String accountPath,
      String userId, {String? quicknoteCategory}) async {
    await _ensureTableExists();

    const expectedAccountPathParts = ['account', 'user', 'details'];
    final actualAccountPathParts =
    accountPath.split('~').where((p) => p.isNotEmpty).toList();

    if (actualAccountPathParts.length != expectedAccountPathParts.length ||
        !listEquals(actualAccountPathParts, expectedAccountPathParts)) {
      throw Exception(
          'Invalid accountPath for getQuicknote. Expected "account~user~details".');
    }

    try {
      Map<dynamic, dynamic>? accountData = await readData(accountPath, userId);
      Map<String, dynamic> currentJsonData =
      (accountData != null && accountData is Map<String, dynamic>)
          ? accountData
          : <String, dynamic>{};

      List<dynamic> quicknotesList = (currentJsonData['quicknote'] != null &&
          currentJsonData['quicknote'] is List<dynamic>)
          ? currentJsonData['quicknote'] as List<dynamic>
          : <dynamic>[];

      if (quicknoteCategory != null && quicknoteCategory.isNotEmpty) {
        // Return only the list for the specified quicknoteCategory
        for (final entry in quicknotesList) {
          if (entry is Map<String, dynamic> &&
              entry.containsKey(quicknoteCategory)) {
            print(
                "Retrieved quicknotes for category '$quicknoteCategory' for user: $userId");
            return [entry]; // Return as a list containing just this map
          }
        }
        print("No quicknotes found for category '$quicknoteCategory' for user: $userId.");
        return []; // Return empty list if specific category not found
      } else {
        // Return the entire 'quicknote' list
        final List<Map<String, dynamic>> allQuicknotes =
        quicknotesList.whereType<Map<String, dynamic>>().toList();
        print("Retrieved all quicknotes for user: $userId");
        return allQuicknotes; // Returns the full quicknote list
      }
    } catch (e) {
      print(
          "Error getting quicknote data for user $userId, category $quicknoteCategory: $e");
      return null; // Indicates a retrieval error
    }
  }
}
