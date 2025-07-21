// lib/models/db_details.dart
import 'package:intl/intl.dart'; // For date parsing if needed

class DBdetails {
  final int? id;
  final int? dashboardDomainId; // Can be null
  final String? domain;
  final String? lastAuctionRefreshTime; // String, might be ISO 8601 or similar
  final String? lastAuctionRefreshAttemptTime; // String, can be null
  final String? highBidder; // Can be null
  final int? acquiShortlistedDomainId; // Can be null
  final int? sleepStatus;
  final String? bidScheduledTime; // Date as String, can be null
  final String? wonby; // Can be null
  final String? wonat; // Can be null
  final double? myLastBid; // Float in Java usually maps to double
  final double? minNextBid; // Float in Java usually maps to double
  final double? renewPrice; // Float in Java usually maps to double
  final bool? fastBid;
  final String? fastBidAmount; // Can be null
  final int? fastI;
  final int? fastN;
  final int? bothAccount;
  final String? preBidAmount; // Can be null
  final bool? accountSwitched;
  final bool? account;
  final bool? wasWatchlisted; // Can be null
  final bool? mute;
  final int? gdv; // Can be null
  final bool? fetched; // Can be null
  final String? namecheapid; // Can be null
  final int? auctionId; // Long in Java maps to int or BigInt in Dart, use int?
  final String? mymaxbid; // Can be null
  final String? platform;
  final bool? track;
  final bool? bidBufferChanged;
  final bool? notUpdating;
  final String? currbid; // Current bid as String
  final int? bidders; // Can be null, Long in Java maps to int?
  final String? timeLeft; // E.g., "1m", "6h", "7d"
  final int? age; // Long in Java maps to int?
  final int? bids; // Integer in Java maps to int?
  final int? estibot; // Can be null
  final String? auctiontype;
  final bool? watchlist;
  final bool? scheduled;
  final bool? addedToDan;
  final String? url; // Can be null
  final int? nw;
  final int? extensionsTaken; // Can be null
  final String? bidAmount; // Our bid amount as String
  final String? result; // E.g., "Bid Placed", "Outbid", "Bid Scheduled"
  final String? endTimepst; // E.g., "05/22/2025 12:13 PM (PDT)"
  final String? endTimeist; // E.g., "2025-05-23 00:43 IST"
  final String? bidplacetime; // Can be null
  final bool? approachWarn;
  final bool? estFlag;
  final int? keywordExactLsv; // Can be null
  final double? keywordExactCpc; // Can be null
  final String? whoisCreateDate; // E.g., "2024-04-20"
  final String? whoisRegistrar; // Can be null
  final int? endUsersBuyers; // Can be null
  final int? waybackAge; // Can be null
  final int? appraisedWholesaleValue; // Can be null
  final int? numWords; // Can be null
  final int? isCctld; // Can be null
  final int? isNtld; // Can be null
  final int? isAdult; // Can be null
  final int? isReversed; // Can be null
  final int? numNumbers; // Can be null
  final int? sldLength; // Can be null
  final int? searchAdsPhrase; // Can be null
  final int? hasTrademark; // Can be null
  final int? backlinks; // Can be null
  final int? waybackRecords; // Can be null
  final bool? apiResultVerified; // Can be null
  final int? pronounceabilityScore; // Can be null
  final String? language; // Can be null
  final double? languageProbability; // Can be null
  final String? category; // Can be null
  final String? categoryRoot; // Can be null
  final String? firstWord; // Can be null
  final String? secondWord; // Can be null
  final bool? bidPlaced; // Java's isBidPlaced becomes bidPlaced in JSON

  DBdetails({
    this.id,
    this.dashboardDomainId,
    this.domain,
    this.lastAuctionRefreshTime,
    this.lastAuctionRefreshAttemptTime,
    this.highBidder,
    this.acquiShortlistedDomainId,
    this.sleepStatus,
    this.bidScheduledTime,
    this.wonby,
    this.wonat,
    this.myLastBid,
    this.minNextBid,
    this.renewPrice,
    this.fastBid,
    this.fastBidAmount,
    this.fastI,
    this.fastN,
    this.bothAccount,
    this.preBidAmount,
    this.accountSwitched,
    this.account,
    this.wasWatchlisted,
    this.mute,
    this.gdv,
    this.fetched,
    this.namecheapid,
    this.auctionId,
    this.mymaxbid,
    this.platform,
    this.track,
    this.bidBufferChanged,
    this.notUpdating,
    this.currbid,
    this.bidders,
    this.timeLeft,
    this.age,
    this.bids,
    this.estibot,
    this.auctiontype,
    this.watchlist,
    this.scheduled,
    this.addedToDan,
    this.url,
    this.nw,
    this.extensionsTaken,
    this.bidAmount,
    this.result,
    this.endTimepst,
    this.endTimeist,
    this.bidplacetime,
    this.approachWarn,
    this.estFlag,
    this.keywordExactLsv,
    this.keywordExactCpc,
    this.whoisCreateDate,
    this.whoisRegistrar,
    this.endUsersBuyers,
    this.waybackAge,
    this.appraisedWholesaleValue,
    this.numWords,
    this.isCctld,
    this.isNtld,
    this.isAdult,
    this.isReversed,
    this.numNumbers,
    this.sldLength,
    this.searchAdsPhrase,
    this.hasTrademark,
    this.backlinks,
    this.waybackRecords,
    this.apiResultVerified,
    this.pronounceabilityScore,
    this.language,
    this.languageProbability,
    this.category,
    this.categoryRoot,
    this.firstWord,
    this.secondWord,
    this.bidPlaced,
  });

  factory DBdetails.fromJson(Map<String, dynamic> json) {
    return DBdetails(
      id: json['id'] as int?,
      dashboardDomainId: json['dashboardDomainId'] as int?,
      domain: json['domain'] as String?,
      lastAuctionRefreshTime: json['lastAuctionRefreshTime'] as String?,
      lastAuctionRefreshAttemptTime: json['lastAuctionRefreshAttemptTime'] as String?,
      highBidder: json['highBidder'] as String?,
      acquiShortlistedDomainId: json['acquiShortlistedDomainId'] as int?,
      sleepStatus: json['sleepStatus'] as int?,
      bidScheduledTime: json['bidScheduledTime'] as String?,
      wonby: json['wonby'] as String?,
      wonat: json['wonat'] as String?,
      myLastBid: (json['myLastBid'] as num?)?.toDouble(), // num? to handle int or double from JSON
      minNextBid: (json['minNextBid'] as num?)?.toDouble(),
      renewPrice: (json['renewPrice'] as num?)?.toDouble(),
      fastBid: json['fastBid'] as bool?,
      fastBidAmount: json['fastBidAmount'] as String?,
      fastI: json['fast_i'] as int?,
      fastN: json['fast_n'] as int?,
      bothAccount: json['bothAccount'] as int?,
      preBidAmount: json['preBidAmount'] as String?,
      accountSwitched: json['accountSwitched'] as bool?,
      account: json['account'] as bool?,
      wasWatchlisted: json['wasWatchlisted'] as bool?,
      mute: json['mute'] as bool?,
      gdv: json['gdv'] as int?,
      fetched: json['fetched'] as bool?,
      namecheapid: json['namecheapid'] as String?,
      auctionId: json['auctionId'] as int?,
      mymaxbid: json['mymaxbid'] as String?,
      platform: json['platform'] as String?,
      track: json['track'] as bool?,
      bidBufferChanged: json['bidBufferChanged'] as bool?,
      notUpdating: json['notUpdating'] as bool?,
      currbid: json['currbid'] as String?,
      bidders: json['bidders'] as int?,
      timeLeft: json['time_left'] as String?,
      age: json['age'] as int?,
      bids: json['bids'] as int?,
      estibot: json['estibot'] as int?,
      auctiontype: json['auctiontype'] as String?,
      watchlist: json['watchlist'] as bool?,
      scheduled: json['scheduled'] as bool?,
      addedToDan: json['addedToDan'] as bool?,
      url: json['url'] as String?,
      nw: json['nw'] as int?,
      extensionsTaken: json['extensions_taken'] as int?,
      bidAmount: json['bidAmount'] as String?,
      result: json['result'] as String?,
      endTimepst: json['endTimepst'] as String?,
      endTimeist: json['endTimeist'] as String?,
      bidplacetime: json['bidplacetime'] as String?,
      approachWarn: json['approachWarn'] as bool?,
      estFlag: json['estFlag'] as bool?,
      keywordExactLsv: json['keyword_exact_lsv'] as int?,
      keywordExactCpc: (json['keyword_exact_cpc'] as num?)?.toDouble(),
      whoisCreateDate: json['whois_create_date'] as String?,
      whoisRegistrar: json['whois_registrar'] as String?,
      endUsersBuyers: json['end_users_buyers'] as int?,
      waybackAge: json['wayback_age'] as int?,
      appraisedWholesaleValue: json['appraised_wholesale_value'] as int?,
      numWords: json['num_words'] as int?,
      isCctld: json['is_cctld'] as int?,
      isNtld: json['is_ntld'] as int?,
      isAdult: json['is_adult'] as int?,
      isReversed: json['is_reversed'] as int?,
      numNumbers: json['num_numbers'] as int?,
      sldLength: json['sld_length'] as int?,
      searchAdsPhrase: json['search_ads_phrase'] as int?,
      hasTrademark: json['has_trademark'] as int?,
      backlinks: json['backlinks'] as int?,
      waybackRecords: json['wayback_records'] as int?,
      apiResultVerified: json['apiResultVerified'] as bool?,
      pronounceabilityScore: json['pronounceability_score'] as int?,
      language: json['language'] as String?,
      languageProbability: (json['language_probability'] as num?)?.toDouble(),
      category: json['category'] as String?,
      categoryRoot: json['category_root'] as String?,
      firstWord: json['first_word'] as String?,
      secondWord: json['second_word'] as String?,
      bidPlaced: json['bidPlaced'] as bool?, // Ensure this matches exactly as seen in JSON
    );
  }

  @override
  String toString() {
    return 'DBdetails(domain: $domain, platform: $platform, currbid: $currbid, bidAmount: $bidAmount, endTimeist: $endTimeist, result: $result, scheduled: $scheduled)';
  }


}