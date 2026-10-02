import 'profile_model.dart';
import 'auction_model.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String categoryId;
  final String condition;
  final String location;
  final double latitude;
  final double longitude;
  final String sellingMode; // 'FIX', 'BID', 'FIX_AND_BID'
  final String status; // 'ACTIVE', 'SOLD', 'CANCELLED'
  final int views;
  final DateTime createdAt;
  final List<String> images;
  final ProfileModel? seller;
  final AuctionModel? auction;
  final double? fixedPrice;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    required this.location,
    this.latitude = 22.5726,
    this.longitude = 88.4639,
    required this.sellingMode,
    this.status = 'ACTIVE',
    this.views = 0,
    required this.createdAt,
    this.images = const [],
    this.seller,
    this.auction,
    this.fixedPrice,
  });

  bool get isAuction => sellingMode == 'BID' || sellingMode == 'FIX_AND_BID';
  bool get isFixed => sellingMode == 'FIX' || sellingMode == 'FIX_AND_BID';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imageList = [];
    if (json['product_images'] != null && json['product_images'] is List) {
      imageList = (json['product_images'] as List)
          .map((img) => img['image_url'] as String)
          .toList();
    }

    AuctionModel? auctionObj;
    if (json['auctions'] != null) {
      if (json['auctions'] is List && (json['auctions'] as List).isNotEmpty) {
        auctionObj = AuctionModel.fromJson(json['auctions'][0]);
      } else if (json['auctions'] is Map<String, dynamic>) {
        auctionObj = AuctionModel.fromJson(json['auctions']);
      }
    }

    ProfileModel? sellerObj;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      sellerObj = ProfileModel.fromJson(json['profiles']);
    }

    return ProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as String? ?? 'general',
      condition: json['condition'] as String? ?? 'Used - Good',
      location: json['location'] as String? ?? 'New Town, Kolkata',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 22.5726,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 88.4639,
      sellingMode: json['selling_mode'] as String,
      status: json['status'] as String? ?? 'ACTIVE',
      views: json['views'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      images: imageList,
      seller: sellerObj,
      auction: auctionObj,
      fixedPrice: auctionObj?.buy_now_price,
    );
  }
}
