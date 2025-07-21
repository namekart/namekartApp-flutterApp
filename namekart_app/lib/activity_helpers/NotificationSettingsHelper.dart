// lib/fcm/NotificationSettingsManager.dart
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart'; // Assuming GlobalProviders.userId is here
import 'package:namekart_app/fcm/FcmHelper.dart'; // For FCM subscriptions/unsubscriptions

class NotificationSettingsHelper {
  /// Checks if notification settings are present in the user's account data.
  /// Returns true if 'notifications' section with 'muted' or 'active' lists exists,
  /// indicating the user has interacted with or has pre-existing settings.
  /// Returns false otherwise.
  static Future<bool> isNotificationSettingsPresent(String userId) async {
    try {
      final Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", userId);

      if (accountData != null &&
          accountData.containsKey('notifications') &&
          accountData['notifications'] is Map) {
        final Map<String, dynamic> notificationsSection = accountData['notifications'] as Map<String, dynamic>;
        // Consider settings present if either muted or active lists exist
        return notificationsSection.containsKey('muted') || notificationsSection.containsKey('active');
      }
      return false;
    } catch (e) {
      print("Error checking notification settings presence: $e");
      return false; // Assume not present on error
    }
  }

  /// Subscribes the user to all available notification topics
  /// if no notification settings are found for them.
  /// This function effectively sets all notifications to 'active' by default.
  static Future<void> subscribeToAllNotificationsIfNoneSet(String userId) async {
    final bool settingsPresent = await isNotificationSettingsPresent(userId);

    if (!settingsPresent) {
      print("No notification settings found for user $userId. Subscribing to all available topics.");
      try {
        final List<String> allAvailablePaths = await DbSqlHelper.getAllAvailablePaths(maxDepth: 3);
        final List<String> notificationPaths = allAvailablePaths
            .where((path) => path.startsWith("notifications~"))
            .toList();

        // Subscribe to all these topics
        for (String topic in notificationPaths) {
          await FCMHelper().subscribeToTopic(topic);
          print("Subscribed to FCM topic: $topic");
        }

        // After subscribing, save the initial state to DbAccountHelper
        // All are active, none are muted initially.
        Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", userId);
        accountData ??= <String, dynamic>{};

        Map<String, dynamic> notificationsSection = <String, dynamic>{};
        notificationsSection['muted'] = []; // Initially no topics are muted
        notificationsSection['active'] = notificationPaths; // All are active

        accountData['notifications'] = notificationsSection;

        await DbAccountHelper.addData("account~user~details", userId, accountData);
        print("Initial notification settings saved: all topics active.");

      } catch (e) {
        print("Error subscribing to all notifications: $e");
        // Handle error, maybe show a toast or log
      }
    } else {
      print("Notification settings already present for user $userId. Skipping auto-subscription.");
    }
  }

  static Future<bool> isNotificationPathManaged(String userId, String path) async {
    try {
      final Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", userId);

      if (accountData != null &&
          accountData.containsKey('notifications') &&
          accountData['notifications'] is Map) {
        final Map<String, dynamic> notificationsSection = accountData['notifications'] as Map<String, dynamic>;

        final Set<String> userMutedItems = Set<String>.from((notificationsSection['muted'] as List?)?.cast<String>() ?? []);
        final Set<String> userActiveItems = Set<String>.from((notificationsSection['active'] as List?)?.cast<String>() ?? []);

        return userMutedItems.contains(path) || userActiveItems.contains(path);
      }
      return false; // No notification section, so path is not managed
    } catch (e) {
      print("Error checking if notification path is managed: $e");
      return false;
    }
  }
}