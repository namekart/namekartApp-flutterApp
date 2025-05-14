class AuctionList {
  String auctionId;
  int est;
  String domain;
  int age;
  int gdv;
  int currentBidPrice;
  String highlightType;

  // Default constructor
  AuctionList({
    required this.auctionId,
    required this.est,
    required this.domain,
    required this.age,
    required this.gdv,
    required this.currentBidPrice,
    required this.highlightType
  });

  // Factory constructor to create an instance from JSON
  factory AuctionList.fromJson(Map<String, dynamic> json) {
    return AuctionList(
      auctionId: json['auction_id'] ?? '',
      est: json['est'] ?? 0,
      domain: json['domain'] ?? '',
      age: json['age'] ?? 0,
      gdv: json['gdv'] ?? 0,
      currentBidPrice: json['current_bid_price'] ?? 0,
      highlightType: json['highlightType']??'',
    );
  }

  // Method to convert the instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'auction_id': auctionId,
      'est': est,
      'domain': domain,
      'age': age,
      'gdv': gdv,
      'current_bid_price': currentBidPrice,
      'highlightType':highlightType,
    };
  }

  // Factory constructor to create a list of AuctionList objects from JSON
  static List<AuctionList> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AuctionList.fromJson(json)).toList();
  }
}
