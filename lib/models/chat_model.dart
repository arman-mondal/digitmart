import 'product_model.dart';
import 'profile_model.dart';

class ChatModel {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final ProductModel? product;
  final ProfileModel? buyer;
  final ProfileModel? seller;

  ChatModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.product,
    this.buyer,
    this.seller,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    ProductModel? productObj;
    if (json['products'] != null && json['products'] is Map<String, dynamic>) {
      productObj = ProductModel.fromJson(json['products']);
    }

    ProfileModel? buyerObj;
    if (json['buyer'] != null && json['buyer'] is Map<String, dynamic>) {
      buyerObj = ProfileModel.fromJson(json['buyer']);
    }

    ProfileModel? sellerObj;
    if (json['seller'] != null && json['seller'] is Map<String, dynamic>) {
      sellerObj = ProfileModel.fromJson(json['seller']);
    }

    return ChatModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      product: productObj,
      buyer: buyerObj,
      seller: sellerObj,
    );
  }
}
