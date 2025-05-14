import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';




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


