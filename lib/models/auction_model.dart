class AuctionModel {
  final String id;
  final String productId;
  final double startingPrice;
  final double currentPrice;
  final double minimumIncrement;
  final double? reservePrice;
  final double? buy_now_price;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? extendedUntil;
  final String status; // 'ACTIVE', 'ENDING', 'ENDED', 'RESERVE_NOT_MET', etc.
  final String? winnerId;
  final int totalBids;

  AuctionModel({
    required this.id,
    required this.productId,
    required this.startingPrice,
    required this.currentPrice,
    this.minimumIncrement = 500.0,
    this.reservePrice,
    this.buy_now_price,
    required this.startTime,
    required this.endTime,
    this.extendedUntil,
    required this.status,
    this.winnerId,
    this.totalBids = 0,
  });

  DateTime get effectiveEndTime => extendedUntil ?? endTime;

  bool get isEndingSoon {
    final diff = effectiveEndTime.difference(DateTime.now());
    return diff.inMinutes <= 60 && diff.inSeconds > 0;
  }

  bool get isExpired => DateTime.now().isAfter(effectiveEndTime);

  bool get reserveMet =>
      reservePrice == null || currentPrice >= reservePrice!;

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      startingPrice: (json['starting_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      minimumIncrement: (json['minimum_increment'] as num?)?.toDouble() ?? 500.0,
      reservePrice: (json['reserve_price'] as num?)?.toDouble(),
      buy_now_price: (json['buy_now_price'] as num?)?.toDouble(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      extendedUntil: json['extended_until'] != null
          ? DateTime.parse(json['extended_until'] as String)
          : null,
      status: json['status'] as String? ?? 'ACTIVE',
      winnerId: json['winner_id'] as String?,
      totalBids: json['total_bids'] as int? ?? 0,
    );
  }
}
