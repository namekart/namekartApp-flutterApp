import 'dart:convert';

import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

class HiveHelper {
  static final Box _box = Hive.box('storage');
  static const String rootKey = 'root';
  static final _uuid = Uuid();

  /// Fetch root structure safely
  static Map<dynamic, dynamic> _getRoot() {
    final raw = _box.get(rootKey);
    return raw == null ? {} : Map<dynamic, dynamic>.from(raw);
  }

  /// Save updated root structure
  static void _saveRoot(Map<dynamic, dynamic> root) {
    _box.put(rootKey, root);
  }

  static Future<String> addDataToHive(String path, String id, Map<dynamic, dynamic> info) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty && path.isNotEmpty) {
      throw Exception('Path is invalid');
    }

    final root = _getRoot();

    // Traverse to the parent node
    Map<dynamic, dynamic> node = root;
    for (final part in parts) {
      if (!node.containsKey(part)) {
        node[part] = <dynamic, dynamic>{};
      } else {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
      }
      node = node[part];
    }

    // Check if the entry already exists
    if (node.containsKey(id)) {
      throw Exception('Entry with ID $id already exists');
    }

    // Optional: Clean up unexpected 'id' key in the parent node
    if (node.containsKey('id')) {
      node.remove('id');
    }

    // Add the new entry
    String usedKey = id;
    node[id] = {
      'id': id,
      ...info,
    };

    // Save the updated root
    _saveRoot(root);

    return usedKey;
  }

  static Future<String> updateDataOfHive(String path, String id, Map<dynamic, dynamic> info) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty && path.isNotEmpty) {
      throw Exception('Path is invalid');
    }

    final root = _getRoot();

    // Traverse to the parent node (stop before the last part if it matches the id)
    Map<dynamic, dynamic> node = root;
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!node.containsKey(part)) {
        throw Exception('Path part $part does not exist');
      } else {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
      }
      node = node[part];
    }

    // The last part of the path should match the id
    final lastPart = parts.last;
    if (lastPart != id) {
      throw Exception('Last part of path does not match provided id');
    }

    // Check if the entry exists
    if (!node.containsKey(id)) {
      throw Exception('Entry with ID $id does not exist');
    }

    // Optional: Clean up unexpected 'id' key in the parent node
    if (node.containsKey('datetime_id')) {
      node.remove('datetime_id');
    }

    // Replace the existing entry with the new info
    String usedKey = id;
    node[id] = {
      'datetime_id': id,
      ...info,
    };

    // Save the updated root
    _saveRoot(root);

    return usedKey;
  }
  static dynamic read(String path) {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    final root = _getRoot();
    dynamic node = root;


    for (final part in parts) {
      if (node is Map && node.containsKey(part)) {
        node = Map<dynamic, dynamic>.from(node[part]);
      } else {
        return null;
      }
    }

    return node;
  }

  /// Delete full path or specific item
  static Future<void> delete(String path) async {
    final parts = path.split('~').where((p) => p.isNotEmpty).toList();
    final root = _getRoot();

    if (parts.isEmpty) {
      root.clear();
      _saveRoot(root);
      return;
    }

    Map<dynamic, dynamic> node = root;
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (node.containsKey(part)) {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
        node = node[part];
      } else {
        return;
      }
    }

    node.remove(parts.last);
    _saveRoot(root);
  }


  /// Get a specific item by ID
  static Map<dynamic, dynamic>? getById(String path, String id) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final root = _getRoot();
    dynamic node = root;

    for (final part in parts) {
      if (node is Map && node.containsKey(part)) {
        node = Map<dynamic, dynamic>.from(node[part]);
      } else {
        return null;
      }
    }

    if (node is Map && node.containsKey(id)) {
      return Map<dynamic, dynamic>.from(node[id]);
    }

    return null;
  }

  /// List child keys at any path
  static List getKeys(String path) {
    final data = read(path);
    if (data is Map<dynamic, dynamic>) {
      return data.keys.toList();
    }
    return [];
  }

  /// Get the last (latest) element at a given path based on numeric ID
  static Map<dynamic, dynamic>? getLast(String path) {
    final rawData = read(path);

    if (rawData == null) return null;

    dynamic data;
    try {
      data = (rawData is String) ? jsonDecode(rawData) : rawData;
    } catch (_) {
      return null;
    }

    if (data is! Map<dynamic, dynamic>) return null;

    Map<dynamic, dynamic>? latestValue;
    DateTime? latestTime;

    for (final entry in data.entries) {
      final value = entry.value;

      if (value is Map<dynamic, dynamic>) {
        final dtId = value['datetime_id'] ?? entry.key;
        final parsed = DateTime.tryParse(dtId);

        if (parsed == null) continue;

        if (latestTime == null || parsed.isAfter(latestTime)) {
          latestTime = parsed;
          latestValue = Map<dynamic, dynamic>.from(value);
        }
      }
    }

    return latestValue;
  }



  static List<Map<dynamic, dynamic>> getDataForDate(String path, String targetDate) {
    final data = read(path);
    if (data is! Map<dynamic, dynamic>) return [];

    final matchedItems = <Map<dynamic, dynamic>>[];

    data.forEach((key, value) {
      if (value.containsKey('datetime_id')) {
        try {
          final entryDateOnly = value['datetime_id'];


          if (entryDateOnly.toString().contains(targetDate)) {
            matchedItems.add(Map<dynamic, dynamic>.from(value));
          }
        } catch (e) {
          print('Debug: Error parsing datetime for key $key: $e');
        }
      }
    });

    return matchedItems;
  }
  static List<Map<dynamic, dynamic>> getFullData(String path) {
    final data = read(path);
    if (data is! Map<dynamic, dynamic>) return [];

    final matchedItems = <Map<dynamic, dynamic>>[];

    data.forEach((key, value) {
      if (value is Map && value.containsKey('datetime_id')) {
        final dt = DateTime.tryParse(value['datetime_id'].toString());
        if (dt != null) {
          matchedItems.add(Map<dynamic, dynamic>.from(value));
        }
      }
    });

    // Sort by datetime_id descending (newest first)
    matchedItems.sort((a, b) {
      final aDate = DateTime.parse(a['datetime_id']);
      final bDate = DateTime.parse(b['datetime_id']);
      return bDate.compareTo(aDate);
    });

    return matchedItems;
  }


  static DateTime? getFirstDate(String path) {
    final data = read(path);
    if (data is! Map<dynamic, dynamic>) return null;

    DateTime? earliest;

    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic> && value.containsKey('datetime')) {
        try {
          final dt = DateTime.parse(value['datetime']);
          if (earliest == null || dt.isBefore(earliest!)) {
            earliest = dt;
          }
        } catch (e) {
          print('Debug: Error parsing datetime for key $key: $e');
        }
      }
    });

    return earliest;
  }



  static Future<Map<dynamic, dynamic>> getPaginatedAuctions(String path, int startIndex) async {
    final data = read(path);
    if (data is! Map<dynamic, dynamic>) {
      return {
        'items': [],
        'count': startIndex,
      };
    }

    // Filter keys less than startIndex
    final filteredKeys = data.keys
        .map((k) => int.tryParse(k))
        .where((k) => k != null && k < startIndex)
        .cast<int>()
        .toList();

    // Sort by descending ID
    filteredKeys.sort((a, b) => b.compareTo(a));

    // Take only the latest 30 items
    final pagedKeys = filteredKeys.take(30).toList();

    // Collect the items
    final items = pagedKeys.map((id) {
      final item = Map<dynamic, dynamic>.from(data[id.toString()]);
      return item;
    }).toList();

    // New count is the starting point for next batch
    final newCount = pagedKeys.isNotEmpty ? pagedKeys.last : startIndex;

    return {
      'items': items,
      'count': newCount,
    };
  }

  /// Count all direct children under [path] whose 'read' == 'no'
  static int getUnreadCountFlexible(String path) {
    final node = read(path);
    if (node is! Map<dynamic, dynamic>) return 0;


    int count = 0;
    node.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        if (value['read'] == 'no') {
          count++;
        }
      }
    });

    return count;
  }

  static int getHomeScreenReadCount() {
    final ampLiveNode = read("notifications~AMP-LIVE");
    if (ampLiveNode is! Map) return 0;

    int count = 0;

    ampLiveNode.forEach((provider, idsMap) {
      if (idsMap is Map) {
        idsMap.forEach((id, data) {
          if (data is Map && data['read'] == 'no') {
            count++;
          }
        });
      }
    });

    return count;
  }


  static int getChannelScreenReadCount() {
    final notificationsNode = read("notifications");
    if (notificationsNode is! Map) return 0;

    int count = 0;

    notificationsNode.forEach((subKey, subNode) {
      if (subKey == "AMP-LIVE") return; // skip home section

      if (subNode is Map) {
        subNode.forEach((subSubKey, idsMap) {
          if (idsMap is Map) {
            idsMap.forEach((id, data) {
              if (data is Map && data['read'] == 'no') {
                count++;
              }
            });
          }
        });
      }
    });
    return count;
  }






  static List<Map<dynamic, dynamic>> searchInDataList(List<Map<dynamic, dynamic>> dataList, String query) {
    final lowerQuery = query.toLowerCase().trim();

    return dataList.where((entry) {
      final data = entry['data'];
      if (data is Map) {
        return data.values.any((value) =>
            value.toString().toLowerCase().contains(lowerQuery));
      }
      return false;
    }).toList();
  }



  static Future<void> markAsRead(String fullPath) async {
    final parts = fullPath.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.length < 1) return;

    final root = _getRoot();
    dynamic node = root;

    // Traverse to the second-last level
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (node is Map && node.containsKey(part)) {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
        node = node[part];
      } else {
        print("returned");
        return;
      }
    }

    final lastKey = parts.last;

    // Update the 'read' field if the final node exists and is a map
    if (node is Map && node.containsKey(lastKey)) {
      final item = Map<dynamic, dynamic>.from(node[lastKey]);
      item['read'] = 'yes';
      node[lastKey] = item;
      print("worked");

      _saveRoot(root);
    }
  }

  static Future<void> markAllAsRead(String partialPath) async {
    final parts = partialPath.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return;

    final root = _getRoot();
    dynamic node = root;

    // Traverse to the target node (not the leaf level)
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (node is Map && node.containsKey(part)) {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
        node = node[part];
      } else {
        print("Path not found");
        return;
      }
    }

    // At this point, 'node' should be the parent map containing items to mark
    if (node is Map) {
      node.forEach((key, value) {
        if (value is Map) {
          final updatedItem = Map<dynamic, dynamic>.from(value);
          updatedItem['read'] = 'yes';
          node[key] = updatedItem;
        }
      });

      print("All items marked as read");
      _saveRoot(root);
    }
  }



  static List<String> searchPathsContaining(String query) {
    final root = _getRoot();
    final matches = <String>{};
    final lowerQuery = query.toLowerCase();


    bool _isLeafMap(Map value) {
      return value.keys.every((k) => int.tryParse(k.toString()) != null);
    }


    void _deepSearch(dynamic node, List<String> pathSoFar) {
      if (node is Map) {
        // If this is a container of data (map of numeric keys), treat the parent as final
        final allKeys = node.keys.map((k) => k.toString()).toList();
        final isDataContainer = allKeys.every((k) => int.tryParse(k) != null);

        if (isDataContainer) {
          // Only add the parent path if it contains the query
          final parentPath = pathSoFar.join('~').toLowerCase();
          if (parentPath.contains(lowerQuery)) {
            matches.add(pathSoFar.join('~'));
          }
          return; // Stop further traversal
        }

        node.forEach((key, value) {
          final keyStr = key.toString();
          // Skip numeric keys
          if (int.tryParse(keyStr) != null) return;

          final currentPath = [...pathSoFar, keyStr];
          final fullPathStr = currentPath.join('~').toLowerCase();

          // Only add current path if it's NOT just a grouping and NOT already marked as a data container
          if (fullPathStr.contains(lowerQuery) && value is Map && !_isLeafMap(value)) {
            _deepSearch(value, currentPath);
          } else if (fullPathStr.contains(lowerQuery) && value is Map) {
            matches.add(currentPath.join('~'));
          } else {
            _deepSearch(value, currentPath);
          }
        });
      }
    }

    _deepSearch(root, []);
    return matches.toList();
  }

  static List<String> getCategoryPathsOnly() {
    final root = _getRoot();
    final Set<String> categoryPaths = {};

    bool _isDynamicKey(String key) {
      // Heuristics: not just letters, may contain '@', digits, ':', or timestamp-like
      return key.contains('@') || RegExp(r'\d').hasMatch(key) || key.contains(':') || key.contains('T');
    }

    void _traverse(dynamic node, List<String> currentPath) {
      if (node is Map) {
        node.forEach((key, value) {
          final keyStr = key.toString();
          final newPath = [...currentPath, keyStr];

          if (value is Map) {
            // Check if child keys are dynamic
            final dynamicKeys = value.keys.where((k) => _isDynamicKey(k.toString()));
            if (dynamicKeys.isNotEmpty) {
              categoryPaths.add(newPath.join('~'));
            }

            // Continue traversing
            _traverse(value, newPath);
          }
        });
      }
    }

    _traverse(root, []);
    return categoryPaths.toList();
  }




  Future<int> getMatchingIdFromHive({
    required String path,
    required String serverId,
  }) async {
    try {
      final box = await Hive.openBox(path);

      for (var value in box.values) {
        if (value is Map && value.containsKey('id')) {
          if (value['id'].toString() == serverId) {
            return int.tryParse(value['id'].toString()) ?? -1;
          }
        }
      }

      return -1; // Not found
    } catch (e) {
      print("❌ Error reading Hive box '$path': $e");
      return -1; // Fallback: assume not found
    }
  }


  /// Return all entries with `ringalarm == true` and their full paths
  static List<String> getAllAvailablePaths({int maxDepth = 4}) {
    final root = _getRoot();
    final List<String> paths = [];

    void traverse(dynamic node, String currentPath, int currentDepth) {
      if (node is Map && currentDepth < maxDepth) {
        node.forEach((key, value) {
          String newPath = currentPath.isEmpty ? key.toString() : '$currentPath~$key';
          traverse(value, newPath, currentDepth + 1);
        });
      } else {
        // Stop here either because not a Map or maxDepth reached
        if (currentPath.isNotEmpty) {
          paths.add(currentPath);
        }
      }
    }

    traverse(root, '', 0);
    return paths;
  }


  static List<String> getRingAlarmPaths() {
    final root = _getRoot();
    final List<String> ringAlarmPaths = [];

    void traverse(dynamic node, String currentPath) {
      if (node is Map) {
        node.forEach((key, value) {
          String newPath = currentPath.isEmpty ? key.toString() : '$currentPath~$key';

          // If we find a device_notification array, scan it for ringAlarm
          if (key == 'device_notification' && value is List) {
            for (int i = 0; i < value.length; i++) {
              var item = value[i];
              if (item is Map && item.containsKey('ringAlarm')) {
                var ringValue = item['ringAlarm'];
                // Check if ringAlarm is true (string "true" or bool true)
                if (ringValue == true || ringValue == 'true') {
                  ringAlarmPaths.add('$newPath~$i~ringAlarm');
                }
              }
            }
          }

          // Recursively traverse deeper if value is Map or List
          if (value is Map || value is List) {
            traverse(value, newPath);
          }
        });
      } else if (node is List) {
        for (int i = 0; i < node.length; i++) {
          var item = node[i];
          String newPath = '$currentPath~$i';
          if (item is Map || item is List) {
            traverse(item, newPath);
          }
        }
      }
    }

    traverse(root, '');
    return ringAlarmPaths;
  }









  /// Set ringalarm = false for the specified full path
  static Future<void> disableRingAlarm(String fullPath) async {
    final parts = fullPath.split('~').where((p) => p.isNotEmpty).toList();

    if (parts.length < 2) return;

    final root = _getRoot();
    dynamic node = root;

    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (node is Map && node.containsKey(part)) {
        node[part] = Map<dynamic, dynamic>.from(node[part]);
        node = node[part];
      } else {
        return;
      }
    }

    final lastPart = parts.last;

    if (node is Map && node.containsKey(lastPart)) {
      final item = Map<dynamic, dynamic>.from(node[lastPart]);
      item['ringalarm'] = false;
      node[lastPart] = item;
      _saveRoot(root);
    }
  }



}
