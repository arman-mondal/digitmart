import 'profile_model.dart';

class BidModel {
  final String id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final double? maximumAmount; // Keep private for auto-bidding
  final bool isAutoBid;
  final String status; // 'VALID', 'OUTBID', 'WINNING'
  final DateTime createdAt;
  final ProfileModel? bidder;

  BidModel({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    this.maximumAmount,
    this.isAutoBid = false,
    required this.status,
    required this.createdAt,
    this.bidder,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? bidderObj;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      bidderObj = ProfileModel.fromJson(json['profiles']);
    }

    return BidModel(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      bidderId: json['bidder_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      maximumAmount: (json['maximum_amount'] as num?)?.toDouble(),
      isAutoBid: json['is_auto_bid'] as bool? ?? false,
      status: json['status'] as String? ?? 'VALID',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      bidder: bidderObj,
    );
  }
}
