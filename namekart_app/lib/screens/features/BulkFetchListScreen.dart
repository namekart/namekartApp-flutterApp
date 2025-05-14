import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../storageClasses/Auctions.dart';

class BulkFetchListScreen extends StatefulWidget {
  final List<Auctions> auctions;

  BulkFetchListScreen({required this.auctions});

  @override
  State<BulkFetchListScreen> createState() => _BulkFetchListScreenState();
}

class _BulkFetchListScreenState extends State<BulkFetchListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bulk Fetch List",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white, // Clean, neutral background
      body: Container(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: widget.auctions.length,
          itemBuilder: (context, index) {
            final auction = widget.auctions[index];
            return AuctionCard(auction: auction);
          },
        ),
      ),
    );
  }
}

class AuctionCard extends StatelessWidget {
  final Auctions auction;

  AuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain Name
            Text(
              auction.domain ?? "No Domain",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 1),
            SizedBox(height: 8),

            // Auction details row by row
            _buildDetailRow("Base Price", "\$${auction.renewalPrice ?? 'N/A'}"),
            _buildDetailRow("Current Bid", "\$${auction.currentBidPrice ?? 'N/A'}"),
            _buildDetailRow("Max Bid", "\$${auction.maxBidPrice ?? 'N/A'}"),
            _buildDetailRow("Registrar", auction.platform ?? "N/A"),
            _buildDetailRow("Age", "${auction.age ?? 0} years"),
            _buildDetailRow("Time Left", auction.timeLeft ?? "N/A"),
            _buildDetailRow(
              "Status",
              auction.auctionType ?? "N/A",
              valueColor: auction.auctionType == "active" ? Colors.green : Colors.red,
            ),
            SizedBox(height: 12),
            Divider(color: Colors.grey[300], thickness: 1),
            SizedBox(height: 12),

            // Auction Stats (Bids, Bidders, Est. Value)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("Bids", auction.bids?.toString() ?? "0"),
                _buildStat("Bidders", auction.bidders?.toString() ?? "0"),
                _buildStat("Est. Value", "\$${auction.est ?? 'N/A'}"),
              ],
            ),
            SizedBox(height: 20),

            // "View Details" button with gradient
            ElevatedButton(
              onPressed: () {
                // Action for viewing auction details
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40), backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                elevation: 8,
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row widget for auction details display
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  // Stats display like Bids, Bidders, Estimated Value
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
