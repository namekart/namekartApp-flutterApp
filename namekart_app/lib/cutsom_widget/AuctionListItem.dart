import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../activity_helpers/DbSqlHelper.dart';
import '../change_notifiers/WebSocketService.dart';

class AuctionListItem extends StatefulWidget {
  final Map<String, dynamic> auctionData;
  final bool isFirst;
  final bool isLast;
  final String appBarTitle;
  final String hiveDatabasePath;
  final dynamic calenderSelectedDate;
  final String subCollection;
  final Function(String) markAsRead;
  final VoidCallback fetchData;
  final Widget previousButton;
  final Widget nextButton;
  final VoidCallback haptic;
  final Function(BuildContext, Map, String, String, int, String, String, String) showDynamicDialog;

  const AuctionListItem({
    Key? key,
    required this.auctionData,
    required this.isFirst,
    required this.isLast,
    required this.appBarTitle,
    required this.hiveDatabasePath,
    required this.calenderSelectedDate,
    required this.subCollection,
    required this.markAsRead,
    required this.fetchData,
    required this.previousButton,
    required this.nextButton,
    required this.haptic,
    required this.showDynamicDialog,
  }) : super(key: key);

  @override
  State<AuctionListItem> createState() => _AuctionListItemState();
}

class _AuctionListItemState extends State<AuctionListItem> {
  late final Map<String, dynamic> data;
  late final List<dynamic>? buttons;
  late final bool ringStatus;
  late final String readStatus;
  late final String itemId;
  late final String path;
  late final List<dynamic>? actionDoneList;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    data = (widget.auctionData['data'] as Map).cast<String, dynamic>();
    buttons = _getValidButtons(widget.auctionData['uiButtons']);
    ringStatus = _calculateRingStatus();
    readStatus = widget.auctionData['read'] ?? 'no';
    itemId = widget.auctionData['id'].toString();
    path = '${widget.hiveDatabasePath}~$itemId';
    actionDoneList = widget.auctionData['actionsDone'];
  }

  List<dynamic>? _getValidButtons(dynamic uiButtons) {
    return (uiButtons is List && uiButtons.isNotEmpty) ? uiButtons : null;
  }

  bool _calculateRingStatus() {
    try {
      final notification = widget.auctionData['device_notification'].toString();
      return notification.contains("ringAlarm: true");
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleAcknowledge() async {
    //to be writtent
  }

  Future<void> _handleVisibility(double visibleFraction) async {
    if (visibleFraction > 0.9 && readStatus == "no") {
      widget.markAsRead(itemId);
      String path = '$widget.hiveDatabasePath~$itemId';

      await DbSqlHelper.markAsRead(path);
    }
  }


  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('auction-item-$itemId'),
      onVisibilityChanged: (info) => _handleVisibility(info.visibleFraction),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (widget.isFirst) widget.previousButton,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (readStatus == "no") _buildNewBadge(),
              if (ringStatus) _buildAcknowledgeButton(),
              _buildMainCard(),
            ],
          ),
          if (widget.isLast) widget.nextButton,
        ],
      ),
    );
  }

  Widget _buildNewBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 18.0),
      child: Container(
        width: 80.sp,
        height: 30.sp,
        decoration: const BoxDecoration(
          color: Color(0xff4CAF50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Text(
          "New",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 8,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAcknowledgeButton() {
    return GestureDetector(
      onTap: _handleAcknowledge,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0),
        child: Container(
          width: 110,
          decoration: BoxDecoration(
            color: const Color(0xff3DB070),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 1),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Acknowledge",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.close, color: Colors.white, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: ringStatus
            ? const BorderSide(color: Colors.redAccent, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildDataTable(),
            if (buttons != null) _buildActionButtons(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          data['h1'] ?? 'No Title',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: const Color(0xff3F3F41),
          ),
        ),
        if (widget.appBarTitle.contains("Highlights"))
          _buildSortButton(),
      ],
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () => _showSortDialog(context),
      child: const Icon(Icons.compare_arrows_outlined, size: 18),
    );
  }

  void _showSortDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xffF5F5F5),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: const Text("Enter First Row Value To Sort"),
                backgroundColor: const Color(0xffB71C1C),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'i.e Age 6 or modoo.blog or price 10',
                    prefixIcon: Icon(Icons.keyboard),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle sort logic
                    Navigator.pop(ctx);
                  },
                  child: const Text("SORT"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (widget.appBarTitle.contains("Highlights")) {
      return _buildHighlightTable();
    } else {
      return _buildCompactBubbles();
    }
  }

  Widget _buildHighlightTable() {
    final entries = data.entries.where((e) => e.key != 'h1');
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
      },
      children: entries.map((entry) {
        final items = entry.value.toString().split('|').take(3).toList();
        return TableRow(
          children: items.map((item) => _buildTableCell(item)).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          text.trim(),
          style: GoogleFonts.poppins(fontSize: 8, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCompactBubbles() {
    final values = [data['h2'], data['h3'], data['h5']]
        .whereType<String>()
        .join(' | ')
        .split('|');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((item) => _buildBubble(item.trim())).toList(),
    );
  }

  Widget _buildBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 0.5),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 7, color: Colors.black),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 20,
        children: buttons!.map((btn) => _buildButton(btn)).toList(),
      ),
    );
  }

  Widget _buildButton(dynamic buttonData) {
    final key = buttonData.keys.first.toString();
    final button = Map<String, dynamic>.from(buttonData[key]);
    final buttonText = button['button_text'] as String;

    return GestureDetector(
      onTap: () => _handleButtonPress(button, buttonText, key),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            _getButtonIcon(buttonText),
            const SizedBox(height: 10),
            Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w300,
                color: const Color(0xff717171),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleButtonPress(
      Map button, String text, String key) async {
    final buttonIndex = int.parse(key.replaceAll("button", "")) - 1;
    await widget.showDynamicDialog(
      context,
      button,
      widget.subCollection,
      itemId,
      buttonIndex,
      key,
      text,
      data['h1']!,
    );
    widget.fetchData();
    widget.haptic();
  }

  Widget _getButtonIcon(String text) {
    // Your icon mapping logic
    return getIconForButton(text, 15);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            widget.auctionData['datetime'],
            style: GoogleFonts.poppins(
              fontSize: 6,
              fontWeight: FontWeight.w300,
              color: const Color(0xff717171),
            ),
          ),
        ),
        if (actionDoneList != null) _buildActionDoneList(),
      ],
    );
  }

  Widget _buildActionDoneList() {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: actionDoneList!.map((action) => _buildActionChip(action)).toList(),
    );
  }

  Widget _buildActionChip(dynamic action) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Text(
        action.toString(),
        style: GoogleFonts.poppins(
          fontSize: 8,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}