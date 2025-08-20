import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:http/http.dart' as http;

// --- DUMMY CLASSES FOR COMPILATION ---
// Replace these with your actual class imports
class Auctions {}
class BulkFetchListScreen extends StatelessWidget {
  const BulkFetchListScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Results Screen")));
}
// --- END DUMMY CLASSES ---


// --- DATA MODELS ---
class BidInput {
  final TextEditingController domainController = TextEditingController();
  final TextEditingController bidController = TextEditingController();
  final AnimationController animationController;

  BidInput({required TickerProvider vsync})
      : animationController = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 400),
  )..forward();

  void dispose() {
    domainController.dispose();
    bidController.dispose();
    animationController.dispose();
  }
}

class PlatformTheme {
  final String name;
  final String icon;
  final Color color;

  PlatformTheme({required this.name, required this.icon, required this.color});
}

// --- MAIN WIDGET ---
class BulkBid extends StatefulWidget {
  const BulkBid({super.key});

  @override
  State<BulkBid> createState() => _BulkBidState();
}

class _BulkBidState extends State<BulkBid> with TickerProviderStateMixin {
  final List<BidInput> _inputs = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isLoading = false;
  bool _screenVisible = false;

  final List<PlatformTheme> _platformItems = [
    PlatformTheme(name: 'GoDaddy', icon: "godaddy.png", color: const Color(0xFF008341)),
    PlatformTheme(name: 'DropCatch', icon: "dropcatch.png", color: const Color(0xFF2E7BCB)),
    PlatformTheme(name: 'Dynadot', icon: "dynadot.png", color: const Color(0xFFD63E2D)),
    PlatformTheme(name: 'Namecheap', icon: "namecheap.png", color: const Color(0xFFDE3723)),
    PlatformTheme(name: 'NameSilo', icon: "namesilo.png", color: const Color(0xFF007AC1)),
  ];
  late PlatformTheme _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = _platformItems.first;
    _addNewField(isInitial: true);
    // Animate the entire screen in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _screenVisible = true);
    });
  }

  @override
  void dispose() {
    for (var input in _inputs) {
      input.dispose();
    }
    super.dispose();
  }

  // --- CORE LOGIC ---

  void _addNewField({bool isInitial = false}) {
    final newField = BidInput(vsync: this);
    if (isInitial) {
      _inputs.add(newField);
    } else {
      _inputs.add(newField);
      _listKey.currentState?.insertItem(_inputs.length - 1);
      Haptics.vibrate(HapticsType.light);
    }
  }

  void _removeField(int index) {
    if (_inputs.length <= 1) return;
    final fieldToRemove = _inputs[index];
    fieldToRemove.animationController.reverse();
    _listKey.currentState?.removeItem(
        index, (context, animation) => _buildItem(fieldToRemove, animation));
    Future.delayed(const Duration(milliseconds: 400), () {
      _inputs.remove(fieldToRemove);
      fieldToRemove.dispose();
    });
    Haptics.vibrate(HapticsType.medium);
  }

  Future<void> _submitBids({required bool isInstant}) async {
    final validInputs = _inputs
        .where((i) =>
    i.domainController.text.trim().isNotEmpty &&
        i.bidController.text.trim().isNotEmpty)
        .toList();
    if (validInputs.isEmpty) {
      _showFeedbackDialog(isError: true, message: "Please fill in at least one valid bid.");
      return;
    }
    setState(() => _isLoading = true);
    final List<String> auctionData = validInputs
        .map((i) =>
    "${_selectedPlatform.name},${i.domainController.text.trim()},${i.bidController.text.trim()}")
        .toList();
    final endpoint = isInstant ? 'instant' : 'schedule';
    final url = 'http://10.0.2.2:8080/auctions/bulkbid/$endpoint';

    try {
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(auctionData));
      if (response.statusCode == 201) {
        _showFeedbackDialog(isError: false, message: "Bids submitted successfully!");
      } else {
        throw Exception(
            'Failed to submit bids. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showFeedbackDialog(
          isError: true, message: "An error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAllFields() {
    for (int i = _inputs.length - 1; i > 0; i--) _removeField(i);
    _inputs.first.domainController.clear();
    _inputs.first.bidController.clear();
    Haptics.vibrate(HapticsType.heavy);
  }

  void _showFeedbackDialog({required bool isError, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isError ? 'Error' : 'Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!isError) _clearAllFields();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(size: 24),
        title:  Text("Bulk Bid",style: GoogleFonts.manrope(fontWeight: FontWeight.bold,fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearAllFields,
            icon: const Icon(CupertinoIcons.trash, size: 20),
            tooltip: "Clear All",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSlide(
        offset: _screenVisible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _screenVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Column(
            children: [
              _buildPlatformSelector(),
              Expanded(child: _buildMainCard()),
              _buildActionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PLATFORM",
            style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _platformItems.length,
              itemBuilder: (context, index) {
                final item = _platformItems[index];
                final isSelected = _selectedPlatform.name == item.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlatform = item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedPlatform.color.withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: _selectedPlatform.color, width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/images/home_screen_images/livelogos/${item.icon}", width: 20, height: 20),
                          const SizedBox(width: 8),
                          Text(item.name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: isSelected ? _selectedPlatform.color : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    // 🚀 NEW: A single, sleek card containing the list and add button.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedList(
            key: _listKey,
            initialItemCount: _inputs.length,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for Add button
            itemBuilder: (context, index, animation) => _buildItem(_inputs[index], animation),
          ),
          // Add button in the bottom right corner
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              elevation: 10,
              onPressed: _addNewField,
              backgroundColor: _selectedPlatform.color,
              child: const Icon(CupertinoIcons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BidInput item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTextField(item.domainController, 'Domain Name')),
              Container(width: 1, height: 24, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
              SizedBox(width: 90, child: _buildTextField(item.bidController, 'Bid \$', isNumeric: true)),
              if (_inputs.length > 1)
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle, color: Colors.grey, size: 20),
                  onPressed: () => _removeField(_inputs.indexOf(item)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.url,
      style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }

  Widget _buildActionFooter() {
    final themeColor = _selectedPlatform.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => _submitBids(isInstant: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: themeColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Schedule All', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : () => _submitBids(isInstant: true),
              style: FilledButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Bid Instantly', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}