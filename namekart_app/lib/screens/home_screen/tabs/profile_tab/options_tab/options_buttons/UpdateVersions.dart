import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'dart:convert';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class UpdateVersion extends StatefulWidget {
  const UpdateVersion({super.key});

  @override
  State<UpdateVersion> createState() => _UpdateVersionState();
}

class _UpdateVersionState extends State<UpdateVersion> {
  // Data is now structured into categories for better readability
  final Map<String, List<String>> currentVersionFeaturesv1= {
    'Backend & Services': [
      "Implemented Spring Boot server for robust backend services.",
      "Configured Spring Boot backend to support dynamic creation and management of channels, enabling flexible content organization.",
      "Enhanced Spring Boot backend to handle dynamic payloads and trigger notifications based on payload content, enabling smarter real-time updates.",
      "Configured Spring Boot to handle and respond to multiple simultaneous messages from the app, improving backend responsiveness and concurrency support.",
    ],
    'Data & Storage': [
      "Integrated Hive for local data storage, Firestore for general cloud data, and MongoDB for specialized cloud-specific information to ensure a robust multi-tier data architecture.",
      "Added automatic memory management: resets large stored data sets to prevent out-of-memory issues and ensure smooth app performance.",
      "Optimized storage by retaining only the latest 2 days of data, automatically removing older entries to reduce memory usage.",
      "Implemented saving of bubble button clicks in both local and cloud storage to minimize server load and ensure faster, more responsive operations.",
    ],
    'Authentication & Sync': [
      "Added Microsoft account login for secure authentication.",
      "Enabled automatic cloud sync immediately upon login to ensure all user data and bubbles are up to date.",
      "Added WebSocket synchronization with auto-reconnect; displays a snackbar notification if the connection drops and reconnects seamlessly.",
    ],
    'Core Features & UI': [
      "Introduced a universal live screen for all channels, featuring separate sections for live content and highlights. Includes an infinite scroll list that loads 10 additional items from the cloud when local data is unavailable. Added a quick-view notification bar with a counter and a down button for instant access to new updates. Integrated a calendar view that displays data by date, with a bottom sheet for date selection and an advanced search option for precise queries.",
      "Configured the live screen to handle dynamic payloads, enabling real-time updates and adaptive content rendering based on incoming data.",
      "Added a comprehensive search screen that allows users to search across all app data for a unified, streamlined discovery experience.",
      "Introduced a channel tab to display live bubble information, added a dedicated search screen for quickly locating specific bubbles, and included a notification indicator for real-time updates.",
      "Added an options tab featuring quick-access tools such as personal groups, quick notes, analytics dashboard, domain insights, hashtags, 'spotted something wrong' feedback, 'have a feature in mind' suggestions, and upgrade information for enhanced user support and interaction.",
      "Added a profile screen to display user details, Firestore data, notification settings, and a logout option for streamlined account management.",
      "Added a Firestore screen page to display comprehensive details of all cloud-stored data, providing clear visibility into user-related cloud content.",
    ],
    'Productivity Tools': [
      "Added multiple productivity tools including a bidding list, watch list, bulk bid, and bulk fetch to streamline user workflows and enhance app functionality.",
    ]
  };

  final Map<String, List<String>> currentVersionFeaturesv2= {
    'Backend & Services': [
      "Added notes,hashtags,stars compatibility in backend"
    ],
    'Data & Storage': [
      "Changed local database from hive to sql for faster query",
      "Memory Optimization",
    ],
    'Authentication & Sync': [
      "Added Microsoft account login for ios devices",
      "Added Firestore cloud auto account login for ios devices",
    ],
    'Core Features & UI': [
      "Ui completely changed"
      "Added shimmer replacing loading screen"
      "Added options tab"
      "Added multiple feature like notes,personal groups,analytics,stars"
      "Added star,hashtags,notes features on bubbles"
      "Improved Animations"
      "Made sync process with cloud easy"
    ],
    'Productivity Tools': [
      "Added options menu for notes,personal groups,analytics,stars"
      "Added star,hashtags,notes features on bubbles"
    ]
  };


  final Map<String, List<String>> inDevelopmentFeatures = {
    'Core Features': [
      "Cloud backup of account, for easy access on any devices"
    ],
    'Productivity & Communication': [
      "Chat feature, enabling users to communicate directly within the app without needing external platforms like WhatsApp or Telegram, saving time and streamlining interactions.",
    ],
    'App Customization & Analytics': [
      "Analytics screen to display key app statistics and usage insights, helping users easily track and understand important metrics.",
      "Theme customization, allowing users to choose from multiple themes including dark mode, light mode, and additional color options to personalize their app experience.",
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA), // A gentle off-white background
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          "What's New",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _UpdateSectionCard(
              title: "Beta Version 1",
              iconAsset:
              "assets/images/home_screen_images/options_tab/update_version_screen/check.png",
              featureMap: currentVersionFeaturesv1,
              header: Row(
                children: [
                  Image.asset(
                      "assets/images/home_screen_images/carousel_options/whatnewupdate/appstorelogo.png",
                      width: 30,
                      height: 30),
                  const SizedBox(width: 10),
                  Image.asset(
                      "assets/images/home_screen_images/carousel_options/whatnewupdate/googleplaylogo.png",
                      width: 30,
                      height: 30),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _UpdateSectionCard(
              title: "Beta Version 1.1",
              iconAsset:
              "assets/images/home_screen_images/options_tab/update_version_screen/check.png",
              featureMap: currentVersionFeaturesv2,
              header: Row(
                children: [
                  Image.asset(
                      "assets/images/home_screen_images/carousel_options/whatnewupdate/appstorelogo.png",
                      width: 30,
                      height: 30),
                  const SizedBox(width: 10),
                  Image.asset(
                      "assets/images/home_screen_images/carousel_options/whatnewupdate/googleplaylogo.png",
                      width: 30,
                      height: 30),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _UpdateSectionCard(
              title: "Currently In Development",
              iconAsset:
              "assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png",
              featureMap: inDevelopmentFeatures,
              header: Image.asset(
                  "assets/images/home_screen_images/options_tab/update_version_screen/coding.png",
                  width: 30,
                  height: 30),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable card widget to display a section of updates.
class _UpdateSectionCard extends StatelessWidget {
  final String title;
  final String iconAsset;
  final Map<String, List<String>> featureMap;
  final Widget header;

  const _UpdateSectionCard({
    required this.title,
    required this.iconAsset,
    required this.featureMap,
    required this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              header,
              const SizedBox(width: 16),
              text(
                  text: title,
                  size: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
            ],
          ),
          const Divider(height: 32),
          // Categorized Features
          ...featureMap.entries.map((entry) {
            return _FeatureCategory(
              categoryTitle: entry.key,
              features: entry.value,
              iconAsset: iconAsset,
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// A widget to display a single category of features.
class _FeatureCategory extends StatelessWidget {
  final String categoryTitle;
  final List<String> features;
  final String iconAsset;

  const _FeatureCategory({
    required this.categoryTitle,
    required this.features,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text(
            text: categoryTitle,
            size: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => _FeatureListItem(
            text1: feature,
            iconAsset: iconAsset,
          )),
        ],
      ),
    );
  }
}

/// A widget for a single feature list item.
class _FeatureListItem extends StatelessWidget {
  final String text1;
  final String iconAsset;

  const _FeatureListItem({required this.text1, required this.iconAsset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Image.asset(iconAsset, width: 18, height: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: text(
              text: text1,
              size: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400, // Increased for readability
            ),
          ),
        ],
      ),
    );
  }
}












