import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart'; // Import DbSqlHelper

import '../../../../../activity_helpers/UIHelpers.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, Map<String, List<String>>> _displayNotificationsMap = {};
  late Set<String> _mutedItems;
  late Set<String> _initialMutedItems;
  bool _isLoading = true; // For initial loading
  bool _isSaving = false; // For save button state

  @override
  void initState() {
    super.initState();
    _mutedItems = {};
    _initialMutedItems = {};
    _loadNotificationSettings();
  }

  // --- All your data loading and mapping logic remains unchanged ---
  Future<void> _loadNotificationSettings() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final List<String> allAvailablePaths =
      await DbSqlHelper.getAllAvailablePaths(maxDepth: 3);
      final List<String> notificationPaths =
      allAvailablePaths.where((path) => path.startsWith("notifications~")).toList();

      _displayNotificationsMap = _groupPathsIntoMap(notificationPaths);

      Map<dynamic, dynamic>? accountData =
      await DbAccountHelper.readData("account~user~details", GlobalProviders.userId);

      if (accountData != null &&
          accountData['notifications'] is Map &&
          accountData['notifications']['muted'] is List) {
        _mutedItems = Set<String>.from(accountData['notifications']['muted']);
      } else {
        _mutedItems = {};
      }

      _initialMutedItems = Set<String>.from(_mutedItems);
    } catch (e) {
      print("Error loading notification settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading settings: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, Map<String, List<String>>> _groupPathsIntoMap(List<String> paths) {
    final Map<String, Map<String, List<String>>> groupedMap = {};
    for (String fullPath in paths) {
      final parts = fullPath.split('~');
      if (parts.length >= 3 && parts[0] == "notifications") {
        final mainCategory = parts[1];
        final subKeyOrLeaf = parts[2];
        if (parts.length == 3) {
          groupedMap.putIfAbsent(mainCategory, () => {});
          groupedMap[mainCategory]!.putIfAbsent("default", () => []).add(subKeyOrLeaf);
        } else {
          final subCategory = subKeyOrLeaf;
          final leaf = parts.sublist(3).join('~');
          groupedMap.putIfAbsent(mainCategory, () => {});
          groupedMap[mainCategory]!.putIfAbsent(subCategory, () => []).add(leaf);
        }
      }
    }
    return groupedMap;
  }
  // --- End of data logic ---

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final Set<String> currentMutedItems = Set<String>.from(_mutedItems);
      final Set<String> allNotificationPaths = (await DbSqlHelper.getAllAvailablePaths(maxDepth: 3))
          .where((path) => path.startsWith("notifications~"))
          .toSet();

      final Set<String> currentActiveItems = allNotificationPaths.difference(currentMutedItems);
      final Set<String> topicsBecomingMuted = currentMutedItems.difference(_initialMutedItems);
      final Set<String> topicsBecomingActive = _initialMutedItems.difference(currentMutedItems);

      final fcmHelper = FCMHelper();
      await Future.wait([
        ...topicsBecomingMuted.map((topic) => fcmHelper.unsubscribeFromTopic(topic)),
        ...topicsBecomingActive.map((topic) => fcmHelper.subscribeToTopic(topic)),
      ]);

      Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", GlobalProviders.userId);
      accountData ??= <String, dynamic>{};
      accountData['notifications'] = {
        'muted': currentMutedItems.toList(),
        'active': currentActiveItems.toList(),
      };

      await DbAccountHelper.addData("account~user~details", GlobalProviders.userId, accountData);

      _initialMutedItems = Set<String>.from(currentMutedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text("Notification Settings Saved Successfully")),
        );
      }
    } catch (e) {
      print("Error saving notification settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error saving settings: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA), // A slightly off-white background
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: text(
          text: "Notifications",
          fontWeight: FontWeight.w600,
          size: 18,
          color: Colors.black87
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: _displayNotificationsMap.keys.length,
              itemBuilder: (context, index) {
                final mainKey = _displayNotificationsMap.keys.elementAt(index);
                final subMap = _displayNotificationsMap[mainKey]!;

                return _NotificationCategoryCard(
                  mainCategory: mainKey,
                  subCategoryMap: subMap,
                  mutedItems: _mutedItems,
                  onToggle: (path, isMuted) {
                    setState(() {
                      if (isMuted) {
                        _mutedItems.add(path);
                      } else {
                        _mutedItems.remove(path);
                      }
                    });
                  },
                );
              },
            ),
          ),
          // --- Save Button Area ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : text(
                    text: "Save Settings",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable widget for displaying a main notification category.
class _NotificationCategoryCard extends StatelessWidget {
  final String mainCategory;
  final Map<String, List<String>> subCategoryMap;
  final Set<String> mutedItems;
  final Function(String, bool) onToggle;

  const _NotificationCategoryCard({
    required this.mainCategory,
    required this.subCategoryMap,
    required this.mutedItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: text(
              text: mainCategory,
              size: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: subCategoryMap.entries.map((subEntry) {
                final subKey = subEntry.key;
                final leafList = subEntry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subKey != "default")
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: text(
                          text: subKey,
                          size: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ...List.generate(leafList.length, (index) {
                      final leaf = leafList[index];
                      final path = "notifications~$mainCategory${subKey == 'default' ? '' : '~$subKey'}~$leaf";
                      final isMuted = mutedItems.contains(path);

                      return _NotificationRow(
                        title: leaf,
                        isMuted: isMuted,
                        onToggle: (shouldMute) => onToggle(path, shouldMute),
                        isLast: index == leafList.length - 1,
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable widget for an individual notification toggle row.
class _NotificationRow extends StatelessWidget {
  final String title;
  final bool isMuted;
  final ValueChanged<bool> onToggle;
  final bool isLast;

  const _NotificationRow({
    required this.title,
    required this.isMuted,
    required this.onToggle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: text(
              text: title.replaceAll('-', ' '), // Make titles more readable
              size: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          CupertinoSwitch(
            value: !isMuted, // Switch is "on" when not muted
            onChanged: (value) => onToggle(!value), // onToggle expects "shouldMute"
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}






