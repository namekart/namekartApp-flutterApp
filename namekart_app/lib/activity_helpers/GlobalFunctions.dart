import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';




class DateResult {
  final String formattedDate;
  final DateTime dateTime;

  DateResult({required this.formattedDate, required this.dateTime});
}


DateResult getToday() {
  final format = DateFormat('yyyy-MM-dd');
  DateTime today = DateTime.now();
  String formatted = format.format(today);
  return DateResult(formattedDate: formatted, dateTime: today);
}


DateResult getPreviousDay(String dateString) {
  final format = DateFormat('yyyy-MM-dd');
    DateTime date = format.parse(dateString);
    DateTime previousDay = date.subtract(Duration(days: 1));
    String formatted = format.format(previousDay);
    return DateResult(formattedDate: formatted, dateTime: previousDay);
  }

DateResult? getNextDay(String dateString) {
  final format = DateFormat('yyyy-MM-dd');
  try {
    DateTime date = format.parse(dateString);
    DateTime today = DateTime.now();
    DateTime todayFormatted = DateTime(today.year, today.month, today.day);

    // If the given date is today, return null
    if (date.isAtSameMomentAs(todayFormatted)) {
      return null;
    } else {
      // Otherwise, return the next day
      DateTime nextDay = date.add(Duration(days: 1));
      String formatted = format.format(nextDay);
      return DateResult(formattedDate: formatted, dateTime: nextDay);
    }
  } catch (e) {
    return null; // if parsing fails
  }
}

Map<dynamic, dynamic> autosort(Map<dynamic, dynamic> data, String sortBy) {
  final List<MapEntry<dynamic, dynamic>> stayOnTop = [];
  final List<MapEntry<dynamic, dynamic>> sortable = [];

  String lowerSortBy = sortBy.toLowerCase().trim();

  // Separate 'h1' and the rest
  for (var entry in data.entries) {
    if (entry.key == 'h1') {
      stayOnTop.add(entry);
    } else {
      sortable.add(entry);
    }
  }

  // Extract numeric or domain-based sort value
  String extractSortValue(String value) {
    List<String> parts = value.split('|').map((e) => e.trim()).toList();

    // First part is domain
    String domain = parts.isNotEmpty ? parts[0] : value;

    // Check for numeric fields like Price, Age, etc.
    for (String part in parts) {
      List<String> subfields = part.split('-').map((e) => e.trim()).toList();
      for (String sub in subfields) {
        if (sub.toLowerCase().contains(lowerSortBy)) {
          RegExp numberMatch = RegExp(r'(\d+\.?\d*)');
          var match = numberMatch.firstMatch(sub);
          if (match != null) {
            return match.group(0)!; // numeric value
          }
          return sub; // fallback to text (in rare case)
        }
      }
    }

    // If no field matched, fallback to domain
    return domain;
  }

  // Sort logic
  sortable.sort((a, b) {
    String aVal = extractSortValue(a.value.toString());
    String bVal = extractSortValue(b.value.toString());

    num? aNum = num.tryParse(aVal);
    num? bNum = num.tryParse(bVal);

    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum); // Numeric sort
    } else {
      return aVal.toLowerCase().compareTo(bVal.toLowerCase()); // Alphabetical fallback
    }
  });

  return Map.fromEntries([...stayOnTop, ...sortable]);
}

// Helper function to extract the sort target from string
String extractSortValue(String text, String key) {
  final regex = RegExp(r'(?<=' + RegExp.escape(key) + r'[^a-zA-Z0-9]?)(\d+)', caseSensitive: false);
  final match = regex.firstMatch(text);
  return match != null ? match.group(0)! : '';
}

Future<void> addAllCloudPath(String data) async {
  if(!data.contains("[]")){
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/paths.json');
    await file.writeAsString(data);  // Directly write the string
    print('✅ Path data saved successfully.');
  } catch (e) {
    print('❌ Failed to save path: $e');
  }}
}

/// Read the local file and return the data as a string
Future<String?> readAllCloudPath() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/paths.json');

    if (await file.exists()) {
      final contents = await file.readAsString();  // Return the raw string
      print('📄 Path data loaded successfully.');
      return contents;
    } else {
      print('⚠️ No path data found.');
      return null;
    }
  } catch (e) {
    print('❌ Failed to read path data: $e');
    return null;
  }
}

Future<List<String>> getSubSubCollectionsFromAllFile(String mainCollection, String subCollection) async {
  try {
    final raw = await readAllCloudPath();
    if (raw == null) return [];

    final decodedOuter = jsonDecode(raw);
    final innerJson = decodedOuter['data'];
    final innerDecoded = jsonDecode(innerJson);
    final responseRaw = innerDecoded['response'];
    final List<dynamic> responseList = jsonDecode(responseRaw);

    final List<String> subSubCollections = [];

    for (var item in responseList) {
      if (item is String) {
        final parts = item.split("~");
        if (parts.length == 3 &&
            parts[0] == mainCollection &&
            parts[1] == subCollection) {
          subSubCollections.add(parts[2]);
        }
      }
    }

    print('✅ Found subSubCollections: $subSubCollections');
    return subSubCollections;
  } catch (e, st) {
    print('❌ Error in getSubSubCollections: $e\n$st');
    return [];
  }
}

Future<List<String>> getSubCollections(String mainCollection) async {
  try {
    final raw = await readAllCloudPath();
    if (raw == null) return [];

    final decodedOuter = jsonDecode(raw);
    final innerJson = decodedOuter['data'];
    final innerDecoded = jsonDecode(innerJson);
    final responseRaw = innerDecoded['response'];
    final List<dynamic> responseList = jsonDecode(responseRaw);

    final Set<String> subCollections = {};

    for (var item in responseList) {
      if (item is String) {
        final parts = item.split("~");
        if (parts.length == 3 && parts[0] == mainCollection) {
          subCollections.add(parts[1]);
        }
      }
    }

    final result = subCollections.toList()..sort();
    print("✅ Subcollections for '$mainCollection': $result");
    return result;
  } catch (e, st) {
    print("❌ Error in getSubCollections: $e\n$st");
    return [];
  }
}

Map<String, Map<String, List<String>>> returnMap(List<String> inputList) {
  final Map<String, Map<String, List<String>>> result = {};

  for (String path in inputList) {
    final parts = path.split("~");
    if (parts.length < 3) continue; // skip malformed

    final main = parts[0];
    final sub = parts[1];
    final leaf = parts[2];

    result.putIfAbsent(main, () => {});
    result[main]!.putIfAbsent(sub, () => []);
    result[main]![sub]!.add(leaf);
  }

  return result;
}


String formatToIST(String isoString) {
  // Parse the original ISO string into a UTC DateTime
  DateTime utcTime = DateTime.parse(isoString);

  // Add 5 hours 30 minutes to convert to IST
  DateTime istTime = utcTime.add(Duration(hours: 5, minutes: 30));

  // Format in desired style
  String formatted = DateFormat('h:mm a').format(istTime);

  return formatted;
}



String extractDate(String isoString) {
  try {
    final dt = DateTime.parse(isoString);
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  } catch (e) {
    return 'Invalid date';
  }
}






