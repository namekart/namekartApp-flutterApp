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

import '../../../../../activity_helpers/FirestoreHelper.dart';
import '../../../../../activity_helpers/GlobalFunctions.dart';
import '../../../../../activity_helpers/GlobalVariables.dart';
import '../../../../../activity_helpers/UIHelpers.dart';
import '../../../../../custom_widget/AnimatedAvatarIcon.dart';
import '../../../../../custom_widget/SuperAnimatedWidget.dart';

class FirestoreInfo extends StatefulWidget {
  const FirestoreInfo({super.key});

  @override
  State<FirestoreInfo> createState() => _FirestoreInfoState();
}

class _FirestoreInfoState extends State<FirestoreInfo> {
  List<String> _liveCollections = [];
  List<String> _notificationsCollections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getFirestoreInfo();
  }

  Future<void> _getFirestoreInfo() async {
    try {
      final liveFuture = getSubCollections("live");
      final notificationsFuture = getSubCollections("notifications");
      final results = await Future.wait([liveFuture, notificationsFuture]);
      setState(() {
        _liveCollections = results[0];
        _notificationsCollections = results[1];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching Firestore info: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showInfoBottomSheet(String mainCollection, String subCollection) async {
    // First, fetch the list of items for the tabs
    final tabItems = await getSubSubCollectionsFromAllFile(
        mainCollection, subCollection);
    if (!mounted || tabItems.isEmpty) return;

    // Then, show the bottom sheet with those items
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InfoBottomSheet(
        mainCollection: mainCollection,
        subCollection: subCollection,
        tabItems: tabItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87,size: 24),
        title: Text(
          "Firestore Admin",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black87,fontSize: 14.sp),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            title: "Live",
            collections: _liveCollections,
            iconBuilder: (item) => CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade50,
                child: Text(item.isEmpty ? '?' : item[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800))),
            onTap: (item) => _showInfoBottomSheet("live", item),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: "Notifications",
            collections: _notificationsCollections,
            iconBuilder: (item) => CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade50,
                child: Text(item.isEmpty ? '?' : item[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800))),
            onTap: (item) =>
                _showInfoBottomSheet("notifications", item),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> collections,
    required Widget Function(String) iconBuilder,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: collections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final item = collections[index];
            return _CollectionCard(
              title: item,
              icon: iconBuilder(item),
              onTap: () => onTap(item),
            );
          },
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback onTap;

  const _CollectionCard(
      {required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(height: 20,),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- The Bottom Sheet Widget ---
class _InfoBottomSheet extends StatefulWidget {
  final String mainCollection;
  final String subCollection;
  final List<String> tabItems;

  const _InfoBottomSheet({
    required this.mainCollection,
    required this.subCollection,
    required this.tabItems,
  });

  @override
  State<_InfoBottomSheet> createState() => __InfoBottomSheetState();
}

class __InfoBottomSheetState extends State<_InfoBottomSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.tabItems.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.subCollection,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: widget.tabItems.map((item) => Tab(text: item)).toList(),
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.poppins(),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.tabItems.map((item) {
                    final path = "${widget.mainCollection}/${widget.subCollection}/$item";
                    return _TabContent(collectionPath: path);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Content for each tab in the bottom sheet ---
class _TabContent extends StatefulWidget {
  final String collectionPath;
  const _TabContent({required this.collectionPath});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  int? _documentCount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final count = await getDocumentCount(widget.collectionPath);
      if (mounted) setState(() => _documentCount = count);
    } catch (e) {
      print("Error fetching tab content: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Info Tiles ---
          _InfoTile(
            icon: Icons.folder_copy_outlined,
            title: "Documents",
            value: "${_documentCount ?? 'N/A'}",
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.price_change_outlined,
            title: "Estimated Cost",
            value: "Free Tier",
          ),
          const Divider(height: 48),
          // --- Action Buttons ---
          _ActionButton(
            text: "Delete All Documents",
            icon: Icons.delete_sweep_outlined,
            onPressed: () => showConfirmationDialog(
              context: context,
              title: 'Delete All Documents?',
              content: 'This will delete all documents in this collection but keep the collection itself. This action cannot be undone.',
              onConfirm: () => deleteAllDocumentsInPath(widget.collectionPath),
              snackBarMessage: 'All documents are being deleted.',
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            text: "Delete Channel",
            icon: Icons.delete_forever_outlined,
            onPressed: () => showConfirmationDialog(
              context: context,
              title: 'Delete Channel?',
              content: 'This will delete the entire collection and all its documents. This action cannot be undone.',
              onConfirm: () => deleteCollection(widget.collectionPath),
              snackBarMessage: 'Channel is being deleted.',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
              child: Text(title, style: GoogleFonts.poppins(fontSize: 10))),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const _ActionButton(
      {required this.text, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}






