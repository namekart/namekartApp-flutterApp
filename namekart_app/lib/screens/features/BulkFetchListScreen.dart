import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import '../../storageClasses/Auctions.dart';

class BulkFetchListScreen extends StatefulWidget {
  final List<Auctions> auctions;

  const BulkFetchListScreen({super.key, required this.auctions});

  @override
  State<BulkFetchListScreen> createState() => _BulkFetchListScreenState();
}

class _BulkFetchListScreenState extends State<BulkFetchListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ♻️ REFACTORED AppBar for a cleaner, modern look
      appBar: AppBar(
        title: const Text("Bulk Fetch Results"),
        surfaceTintColor: Colors.white, // Prevents tinting on scroll
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.5, // Adds a subtle shadow on scroll
      ),
      backgroundColor: Colors.white,
      body: AnimationLimiter( // ✨ NEW: Wrapper for list animations
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.auctions.length,
          itemBuilder: (context, index) {
            final auction = widget.auctions[index];
            // ✨ NEW: Applying animations to each list item
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: AuctionCard(auction: auction),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ♻️ REFACTORED AuctionCard with a completely new, modern design
class AuctionCard extends StatelessWidget {
  final Auctions auction;

  const AuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0, // Using border instead of heavy shadow for a cleaner look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200), // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Section: Domain and Main Price ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain Name
                Expanded(
                  child: Text(
                    auction.domain ?? "No Domain",
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                // Current Bid
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${auction.currentBidPrice ?? '0'}",
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Current Bid",
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Middle Section: Info Tags ---
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildInfoTag(
                  icon: CupertinoIcons.time,
                  text: auction.timeLeft ?? "N/A",
                ),
                _buildInfoTag(
                  icon: CupertinoIcons.tag,
                  text: auction.platform ?? "N/A",
                ),
                _buildInfoTag(
                  icon: CupertinoIcons.flame,
                  text: auction.auctionType ?? "N/A",
                  backgroundColor: (auction.auctionType?.toLowerCase() == "active" || auction.auctionType?.toLowerCase() == "buy now")
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  iconColor: (auction.auctionType?.toLowerCase() == "active" || auction.auctionType?.toLowerCase() == "buy now")
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                _buildInfoTag(
                  icon: CupertinoIcons.calendar,
                  text: "${auction.age ?? 0} yrs old",
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.black12),
            const SizedBox(height: 20),

            // --- Bottom Section: Stats & Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  icon: CupertinoIcons.decrease_indent,
                  label: "Bids",
                  value: auction.bids?.toString() ?? "0",
                  textTheme: textTheme,
                ),
                _buildStat(
                  icon: CupertinoIcons.person_2,
                  label: "Bidders",
                  value: auction.bidders?.toString() ?? "0",
                  textTheme: textTheme,
                ),
                _buildStat(
                  icon: CupertinoIcons.graph_square,
                  label: "Est. Value",
                  value: "\$${auction.est ?? 'N/A'}",
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Bounceable( // ✨ NEW: Interactive bounce effect for the button
              onTap: () {
                // Action for viewing auction details
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'View Details',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ NEW: Helper widget for creating modern info tags
  Widget _buildInfoTag({
    required IconData icon,
    required String text,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: iconColor ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ♻️ REFACTORED: Stats display with added icons
  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}