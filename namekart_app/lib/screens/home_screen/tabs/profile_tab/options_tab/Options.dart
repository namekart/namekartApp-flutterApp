import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../../activity_helpers/GlobalVariables.dart';
import '../../../../../activity_helpers/UIHelpers.dart';
import '../../../../../change_notifiers/WebSocketService.dart';
import 'AnalyticsScreen.dart';
import 'options_buttons/PersonalGroup/PersonalGroup.dart';
import 'options_buttons/QuickNotesScreen.dart';
import 'options_buttons/UpdateVersions.dart';
class _OptionItem {
  final String imagePath;
  final VoidCallback? onTap;
  final Widget? targetScreen;

  _OptionItem({
    required this.imagePath,
    this.onTap,
    this.targetScreen,
  }) : assert(onTap != null || targetScreen != null,
  'Either onTap or targetScreen must be provided.');
}

class Options extends StatefulWidget {
  const Options({super.key});

  @override
  State<Options> createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  late final List<_OptionItem> _options;

  @override
  void initState() {
    super.initState();
    // ** ➡️ 2. UPDATED LIST INITIALIZATION **
    // Use `targetScreen` for navigation and `onTap` for other actions.
    _options = [
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/personalgroup.png",
        targetScreen: PersonalGroup(currentUserId: GlobalProviders.userId),
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/quicknotes.png",
        targetScreen: const QuickNotesScreen(),
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/analytics.png",
        targetScreen: const AnalyticsScreen(),
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/hashtags.png",
        onTap: () {
          showTopSnackBar(Overlay.of(context),
              const CustomSnackBar.info(message: "Hashtags feature coming soon!"));
        },
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/spottedsomethingswrong.png",
        onTap: () => _showFeedbackSheet(
          title: "Found a Bug?",
          hint: "How did the bug occur? Please describe the steps to reproduce it.",
          websocketQuery: "bug-reports",
        ),
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/havefeatureinmind.png",
        onTap: () => _showFeedbackSheet(
          title: "Have a Feature in Mind?",
          hint: "Describe your feature idea in detail to help us understand it better.",
          websocketQuery: "suggest-feature",
        ),
      ),
      _OptionItem(
        imagePath: "assets/images/home_screen_images/options_tab/wehaveupgrade.png",
        targetScreen:  UpdateVersion(),
      ),
    ];
  }

  void _showFeedbackSheet({
    required String title,
    required String hint,
    required String websocketQuery,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackBottomSheet(
        title: title,
        hint: hint,
        websocketQuery: websocketQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff7f7f7),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final option = _options[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _OptionCard(item: option),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ** ➡️ 3. CARD IS NOW SMARTER **
/// It decides whether to use ScaleBigScreenTransition or Bounceable.
class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.item});
  final _OptionItem item;

  @override
  Widget build(BuildContext context) {
    // The actual UI of the card content.
    Widget cardContent = Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(item.imagePath, width: 80, height: 80),
        ],
      ),
    );

    // If a targetScreen is provided, wrap with the scale transition.
    if (item.targetScreen != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: ScaleBigScreenTransition(
          targetScreen: item.targetScreen!,
          child: cardContent,
        ),
      );
    }

    // Otherwise, wrap with Bounceable for other tap actions.
    return Bounceable(
      onTap: item.onTap,
      child: cardContent,
    );
  }
}

/// The bottom sheet widget remains unchanged.
class _FeedbackBottomSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String websocketQuery;

  const _FeedbackBottomSheet({
    required this.title,
    required this.hint,
    required this.websocketQuery,
  });

  @override
  State<_FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<_FeedbackBottomSheet> {
  final TextEditingController _editingController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (_editingController.text.trim().isEmpty) {
      Haptics.vibrate(HapticsType.error);
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Details cannot be empty!"),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      WebSocketService w = WebSocketService();
      w.sendMessage({
        "query": widget.websocketQuery,
        "details": _editingController.text.trim(),
      });

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
              message: "Feedback sent successfully! Thank you."),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "An error occurred: $e"),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text(text: widget.title, size: 14, fontWeight: FontWeight.bold,color: Colors.black),
            const SizedBox(height: 20),
            TextField(
              controller: _editingController,
              maxLines: 5,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 10),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : text(
                  text: "Submit Feedback",
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}