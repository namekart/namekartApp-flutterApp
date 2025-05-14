import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class UserSettingsDatabase {
  static Database? _database;
  static final UserSettingsDatabase instance = UserSettingsDatabase._();

  UserSettingsDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'usersettings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE UserAccount(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userName TEXT NOT NULL,
            password TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Adds or updates the single user account.
  /// Returns `"User Added"` if a new user is created.
  /// Returns `"User Data Updated"` if an existing user's data is updated.
  Future<String> addOrUpdateUser(String userName, String password) async {
    Database db = await instance.database;

    // Check if a user already exists
    List<Map<String, dynamic>> existingUsers = await db.query('UserAccount');

    if (existingUsers.isNotEmpty) {
      // User exists, update their credentials
      int userId = existingUsers.first['id'];
      await updateUserAccount(userId, userName, password);
      return "User Data Updated";
    } else {
      // No user exists, insert new record
      await db.insert("UserAccount", {
        'userName': userName,
        'password': password,
      });
      return "User Added";
    }
  }

  /// Retrieves the single user account (if exists).
  Future<Map<String, dynamic>?> getUser() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('UserAccount');
    return result.isNotEmpty ? result.first : null;
  }

  /// Updates user credentials.
  Future<int> updateUserAccount(int id, String userName, String password) async {
    Database db = await instance.database;
    return await db.update(
      'UserAccount',
      {
        'userName': userName,
        'password': password,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes the user account.
  Future<int> deleteUserAccount() async {
    Database db = await instance.database;
    return await db.delete('UserAccount');
  }

  /// Closes the database connection.
  Future close() async {
    Database db = await instance.database;
    db.close();
  }
}
