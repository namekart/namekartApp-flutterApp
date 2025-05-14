class Auctions {
  String? auctionId;
  int? est;
  String? addtime;
  int? age;
  int? bidders;
  int? bids;
  int? currentBidPrice;
  int? maxBidPrice;
  String? domain;
  int? endList;
  String? endTime;
  int? endTimeStamp;
  String? estibotAppraisal;
  int? gdv;
  int? extns;
  int? lsv;
  double? cpc;
  int? eub;
  int? aby;
  int? highlight;
  String? id;
  String? initialList;
  int? live;
  String? platform;
  String? timeLeft;
  String? utfName;
  String? auctionType;
  int? renewalPrice;
  String? appraisal;

  // Default Constructor
  Auctions({
    this.auctionId,
    this.est,
    this.addtime,
    this.age,
    this.bidders,
    this.bids,
    this.currentBidPrice,
    this.maxBidPrice,
    this.domain,
    this.endList,
    this.endTime,
    this.endTimeStamp,
    this.estibotAppraisal,
    this.gdv,
    this.extns,
    this.lsv,
    this.cpc,
    this.eub,
    this.aby,
    this.highlight,
    this.id,
    this.initialList,
    this.live,
    this.platform,
    this.timeLeft,
    this.utfName,
    this.auctionType,
    this.renewalPrice,
    this.appraisal,
  });

  // Factory constructor to create an instance from a JSON object
  factory Auctions.fromJson(Map<String, dynamic> json) {
    return Auctions(
      auctionId: json['auction_id'],
      est: json['est'],
      addtime: json['addtime'],
      age: json['age'],
      bidders: json['bidders'],
      bids: json['bids'],
      currentBidPrice: json['current_bid_price'],
      maxBidPrice: json['max_bid_price'],
      domain: json['domain'],
      endList: json['end_list'],
      endTime: json['end_time'],
      endTimeStamp: json['end_time_stamp'],
      estibotAppraisal: json['estibot_appraisal'],
      gdv: json['gdv'],
      extns: json['extns'],
      lsv: json['lsv'],
      cpc: json['cpc'],
      eub: json['eub'],
      aby: json['aby'],
      highlight: json['highlight'],
      id: json['id'],
      initialList: json['initial_list'],
      live: json['live'],
      platform: json['platform'],
      timeLeft: json['time_left'],
      utfName: json['utf_name'],
      auctionType: json['auction_type'],
      renewalPrice: json['renewal_price'],
      appraisal: json['appraisal'],
    );
  }

  // Method to convert an instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'auction_id': auctionId,
      'est': est,
      'addtime': addtime,
      'age': age,
      'bidders': bidders,
      'bids': bids,
      'current_bid_price': currentBidPrice,
      'max_bid_price': maxBidPrice,
      'domain': domain,
      'end_list': endList,
      'end_time': endTime,
      'end_time_stamp': endTimeStamp,
      'estibot_appraisal': estibotAppraisal,
      'gdv': gdv,
      'extns': extns,
      'lsv': lsv,
      'cpc': cpc,
      'eub': eub,
      'aby': aby,
      'highlight': highlight,
      'id': id,
      'initial_list': initialList,
      'live': live,
      'platform': platform,
      'time_left': timeLeft,
      'utf_name': utfName,
      'auction_type': auctionType,
      'renewal_price': renewalPrice,
      'appraisal': appraisal,
    };
  }
}
