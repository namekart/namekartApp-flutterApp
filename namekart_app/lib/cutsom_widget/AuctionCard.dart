import 'package:flutter/material.dart';

class AuctionUI {
  final String title;
  final List<dynamic> bulletItems;
  final List<ButtonData> buttons;
  final String date;

  AuctionUI({
    required this.title,
    required this.bulletItems,
    required this.buttons,
    required this.date,
  });

  // Factory constructor to convert a Map into an AuctionUI instance
  factory AuctionUI.fromMap(Map<dynamic, dynamic> map) {
    return AuctionUI(
      title: map['title'] ?? '', // Assuming 'title' is a required field
      bulletItems: List<String>.from(map['bulletItems'] ?? []), // Assuming 'bulletItems' is a list of strings
      buttons: (map['buttons'] as List)
          .map((buttonMap) => ButtonData.fromMap(buttonMap))
          .toList(),
      date: map['date'] ?? '',
    );
  }
}

class ButtonData {
  final String label;
  final Map<dynamic, dynamic> onclick;

  ButtonData({
    required this.label,
    required this.onclick,
  });

  factory ButtonData.fromMap(Map<String, dynamic> map) {
    return ButtonData(
      label: map['button_text'] ?? '', // Assuming 'button_text' is a required field
      onclick: map['onclick'] ?? {},
    );
  }
}



class OptimizedAuctionCard extends StatelessWidget {
  final auction;

  const OptimizedAuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auction.title.isNotEmpty)
                Text(
                  auction.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              const SizedBox(height: 8),
              ...auction.bulletItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text("• ", style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: auction.buttons.map((btn) {
                  return TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      debugPrint('Clicked: ${btn.label} → ${btn.onclick}');
                      // TODO: Handle onclick logic here
                    },
                    child: Text(btn.label),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
