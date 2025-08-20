import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';

import '../../../login_screens/LoginScreen.dart';
import 'options/FirestoreInfo.dart';
import 'options/NotificationsScreen.dart';
import 'options/SettingsScreen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userName = GlobalProviders.loginToken.name;
    final String? userEmail = GlobalProviders.loginToken.username;
    // Get the first character of the name, or 'U' as a fallback.
    final String userInitial = (userName != null && userName.isNotEmpty) ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // --- User Profile Header ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.red.shade50,
                  child: text(
                    text: userInitial,
                    size: 28,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                text(
                  text: userName ?? 'User Name',
                  size: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                const SizedBox(height: 5),
                text(
                  text: userEmail ?? 'user@email.com',
                  size: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- Menu Options ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ProfileMenuOption(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>  SettingsScreen()));
                  },
                ),
                _ProfileMenuOption(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>  NotificationsScreen()));
                  },
                ),
                _ProfileMenuOption(
                  title: 'Firestore Info',
                  icon: Icons.data_object_outlined,
                  isLast: true, // To remove the divider for the last item
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>  FirestoreInfo()));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- Logout Button ---
          ElevatedButton(
            onPressed: () {
              // Your existing logout logic
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) =>  LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, size: 20),
                const SizedBox(width: 10),
                text(
                  text: 'Logout',
                  size: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable widget for menu items to avoid code repetition.
class _ProfileMenuOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;

  const _ProfileMenuOption({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(15))
            : BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.grey.shade700),
              const SizedBox(width: 20),
              Expanded(
                child: text(
                  text: title,
                  fontWeight: FontWeight.w500,
                  size: 15,
                  color: Colors.black87,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}