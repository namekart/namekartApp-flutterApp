import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter.blur
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:http/http.dart' as http;
import '../../storageClasses/Auctions.dart';
import 'BulkFetchListScreen.dart';

// --- Models (No changes) ---
class DomainField {
  String selectedPlatform;
  String domainName;
  final TextEditingController controller = TextEditingController();
  DomainField({this.selectedPlatform = 'GoDaddy', this.domainName = ''});
}

class SearchQuery {
  final String platform;
  final String domain;
  SearchQuery({required this.platform, required this.domain});
  Map<String, dynamic> toJson() => {'platform': platform, 'domain': domain};
}

// --- Main Widget ---
class BulkFetch extends StatefulWidget {
  const BulkFetch({super.key});

  @override
  State<BulkFetch> createState() => _BulkFetchState();
}

class _BulkFetchState extends State<BulkFetch> with TickerProviderStateMixin {
  final List<DomainField> _domainFields = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _buttonAnimationController;
  bool _isLoading = false;

  // 🚀 NEW: Defined color palette for a premium look
  static const Color kPrimaryColor = Color(0xFF6A5AE0);
  static const Color kBackgroundColor = Color(0xFFF5F5F7);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF212121);
  static const Color kSubtleTextColor = Color(0xFF616161);

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _addNewField(isInitial: true);
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    for (var field in _domainFields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  void _addNewField({bool isInitial = false}) {
    if (_domainFields.length >= 5) { // Limit to 5 for better UI/performance
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Maximum of 5 domains can be added.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }
    final newField = DomainField();
    if (isInitial) {
      _domainFields.add(newField);
    } else {
      _domainFields.add(newField);
      _listKey.currentState?.insertItem(
        _domainFields.length - 1,
        duration: const Duration(milliseconds: 500),
      );
      Haptics.vibrate(HapticsType.success);
    }
  }

  void _removeField(int index) {
    final removedField = _domainFields.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildItem(removedField, index, animation),
      duration: const Duration(milliseconds: 500),
    );
    Haptics.vibrate(HapticsType.medium);
  }

  Future<void> _submitData() async {
    setState(() => _isLoading = true);
    try {
      final queries = _domainFields
          .where((field) => field.controller.text.trim().isNotEmpty)
          .map((field) => SearchQuery(
        platform: field.selectedPlatform,
        domain: field.controller.text.trim(),
      ))
          .toList();

      if (queries.isEmpty) throw Exception("Please enter at least one domain.");

      final auctions = await _fetchAuctions(queries);

      if (!mounted) return;
      Navigator.push(context, CupertinoPageRoute(
        builder: (context) => BulkFetchListScreen(auctions: auctions),
      ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Auctions>> _fetchAuctions(List<SearchQuery> queries) async {
    const url = 'http://10.0.2.2:8080/auctions/bulkfetch';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(queries.map((q) => q.toJson()).toList()),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((item) => Auctions.fromJson(item)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Bulk Fetch", style: GoogleFonts.manrope(fontWeight: FontWeight.bold,fontSize: 16)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _domainFields.length,
              itemBuilder: (context, index, animation) {
                return _buildItem(_domainFields[index], index, animation);
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // --- 🚀 NEW WIDGETS FOR THE "BEST" DESIGN ---
  // -----------------------------------------------

  Widget _buildItem(DomainField domainField, int index, Animation<double> animation) {
    // 🚀 NEW: Card Stack Animation. Combines multiple transitions for a fluid effect.
    final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
      child: FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curvedAnimation),
          child: Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 20 + (index * 10.0)), // Overlapping effect
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      _buildPlatformSelector(domainField),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Domain Name", style: GoogleFonts.manrope(color: kSubtleTextColor, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: domainField.controller,
                              decoration: InputDecoration.collapsed(hintText: 'example.com', hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400)),
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 16, color: kTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index == _domainFields.length - 1)
                  _buildAddRemoveActions(index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSelector(DomainField domainField) {
    return GestureDetector(
      onTap: () => _showPlatformPicker(domainField),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(
          'assets/images/home_screen_images/livelogos/${domainField.selectedPlatform.toLowerCase()}.png',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  Widget _buildAddRemoveActions(int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_domainFields.length > 1)
            TextButton.icon(
              onPressed: () => _removeField(index),
              icon: const Icon(CupertinoIcons.delete, size: 16),
              label: const Text("Remove"),
              style: TextButton.styleFrom(foregroundColor: kSubtleTextColor),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _addNewField,
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const Text("Add Domain"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              foregroundColor: kPrimaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlatformPicker(DomainField domainField) {
    // 🚀 NEW: Glassmorphism bottom sheet for a premium feel
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for blur effect
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 24),
                  Text('Select Platform', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...['DropCatch', 'Dynadot', 'GoDaddy', 'Namecheap', 'NameSilo'].map((platform) => ListTile(
                    leading: Image.asset('assets/images/home_screen_images/livelogos/${platform.toLowerCase()}.png', width: 32, height: 32),
                    title: Text(platform, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => domainField.selectedPlatform = platform);
                      Navigator.of(context).pop();
                      Haptics.vibrate(HapticsType.selection);
                    },
                  )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    // 🚀 NEW: Animated gradient button
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: AnimatedBuilder(
        animation: _buttonAnimationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: const [Color(0xFF6A5AE0), Color(0xFF8869E8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [_buttonAnimationController.value - 0.5, _buttonAnimationController.value],
              ),
              boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: child,
          );
        },
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoading ? null : _submitData,
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text('Fetch Auction Data', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}