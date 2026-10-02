import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/profile_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/result.dart';
import 'app_logger.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  // 1. SUPABASE AUTHENTICATION
  Future<AppResult<AuthResponse>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
    String locationName = 'Kolkata, West Bengal',
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'location_name': locationName,
        },
      );

      if (response.user != null) {
        await client.from('profiles').upsert({
          'id': response.user!.id,
          'name': name,
          'email': email,
          'phone': phone,
          'location_name': locationName,
          'verification_status': false,
          'rating': 5.0,
          'completed_transactions': 0,
          'bid_reliability': 100,
        });
      }

      return AppResult.success(response);
    } catch (e, st) {
      AppLogger.e('Sign up error', e, st);
      return AppResult.failure(e.toString());
    }
  }

  Future<AppResult<AuthResponse>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AppResult.success(response);
    } catch (e, st) {
      AppLogger.e('Sign in error', e, st);
      return AppResult.failure(e.toString());
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final res = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.fixorbid.fix_or_bid://login-callback',
      );
      return res;
    } catch (e, st) {
      AppLogger.e('Google OAuth error', e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // 2. Fetch User Profile
  Future<AppResult<ProfileModel>> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return AppResult.success(ProfileModel.fromJson(response));
      }
      return AppResult.failure('Profile not found');
    } catch (e, st) {
      AppLogger.e('Error fetching profile', e, st);
      return AppResult.failure('Failed to load profile');
    }
  }

  // 3. Fetch Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e, st) {
      AppLogger.e('Error fetching categories', e, st);
      return [];
    }
  }

  // 4. Fetch Products
  Future<AppResult<List<ProductModel>>> getProducts({
    String? categoryId,
    String? sellingMode,
    String? searchQuery,
    String? status = 'ACTIVE',
  }) async {
    try {
      var query = client.from('products').select('''
        *,
        product_images(*),
        auctions(*),
        profiles:seller_id(*)
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (categoryId != null && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }
      if (sellingMode != null && sellingMode != 'ALL') {
        query = query.eq('selling_mode', sellingMode);
      }

      final data = await query.order('created_at', ascending: false);

      List<ProductModel> products =
          (data as List).map((json) => ProductModel.fromJson(json)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        products = products.where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q)).toList();
      }

      return AppResult.success(products);
    } catch (e, st) {
      AppLogger.e('Error fetching products', e, st);
      return AppResult.failure('Failed to load products');
    }
  }

  // 5. Fetch Single Product Details
  Future<AppResult<ProductModel>> getProductDetails(String productId) async {
    try {
      final data = await client.from('products').select('''
        *,
        product_images(*),
        auctions(*),
        profiles:seller_id(*)
      ''').eq('id', productId).single();

      return AppResult.success(ProductModel.fromJson(data));
    } catch (e, st) {
      AppLogger.e('Error fetching product details', e, st);
      return AppResult.failure('Product not found');
    }
  }

  // 6. SERVER-SIDE RPC Bidding (`place_bid`)
  Future<AppResult<Map<String, dynamic>>> placeBidRpc({
    required String auctionId,
    required double amount,
    double? maxAmount,
  }) async {
    try {
      final response = await client.rpc(
        'place_bid',
        params: {
          'p_auction_id': auctionId,
          'p_amount': amount,
          'p_max_amount': maxAmount,
        },
      );

      final Map<String, dynamic> result = Map<String, dynamic>.from(response);
      if (result['success'] == true) {
        return AppResult.success(result);
      } else {
        return AppResult.failure(result['message'] ?? 'Bidding failed.');
      }
    } catch (e, st) {
      AppLogger.e('Error invoking place_bid RPC', e, st);
      return AppResult.failure(e.toString());
    }
  }

  // 7. SERVER-SIDE RPC Buy Now (`buy_now`)
  Future<AppResult<Map<String, dynamic>>> buyNowRpc(String auctionId) async {
    try {
      final response = await client.rpc(
        'buy_now',
        params: {
          'p_auction_id': auctionId,
        },
      );

      final Map<String, dynamic> result = Map<String, dynamic>.from(response);
      if (result['success'] == true) {
        return AppResult.success(result);
      } else {
        return AppResult.failure(result['message'] ?? 'Buy Now failed.');
      }
    } catch (e, st) {
      AppLogger.e('Error invoking buy_now RPC', e, st);
      return AppResult.failure(e.toString());
    }
  }

  // 8. Fetch Bids for an Auction
  Future<List<BidModel>> getAuctionBids(String auctionId) async {
    try {
      final data = await client.from('bids').select('''
        *,
        profiles:bidder_id(*)
      ''').eq('auction_id', auctionId).order('amount', ascending: false);

      return (data as List).map((json) => BidModel.fromJson(json)).toList();
    } catch (e, st) {
      AppLogger.e('Error fetching bids', e, st);
      return [];
    }
  }

  // 9. Create New Listing
  Future<AppResult<String>> createProductListing({
    required String sellerId,
    required String title,
    required String description,
    required String categoryId,
    required String condition,
    required String location,
    required String sellingMode,
    required String imageUrl,
    double? fixedPrice,
    double? startingPrice,
    double? minIncrement,
    double? reservePrice,
    double? buyNowPrice,
    int durationHours = 24,
  }) async {
    try {
      final productRes = await client.from('products').insert({
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'condition': condition,
        'location': location,
        'selling_mode': sellingMode,
        'fixed_price': fixedPrice,
        'status': 'ACTIVE',
      }).select().single();

      final productId = productRes['id'] as String;

      await client.from('product_images').insert({
        'product_id': productId,
        'image_url': imageUrl,
        'sort_order': 1,
      });

      if (sellingMode == 'BID' || sellingMode == 'FIX_AND_BID') {
        final startPrice = startingPrice ?? 1000.0;
        final now = DateTime.now();
        final endTime = now.add(Duration(hours: durationHours));

        await client.from('auctions').insert({
          'product_id': productId,
          'starting_price': startPrice,
          'current_price': startPrice,
          'minimum_increment': minIncrement ?? 500.0,
          'reserve_price': reservePrice,
          'buy_now_price': buyNowPrice ?? fixedPrice,
          'start_time': now.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'status': 'ACTIVE',
          'total_bids': 0,
        });
      }

      return AppResult.success(productId);
    } catch (e, st) {
      AppLogger.e('Error creating listing', e, st);
      return AppResult.failure(e.toString());
    }
  }

  // 10. Chats & Messages
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final data = await client.from('chats').select('''
        *,
        products(*, product_images(*)),
        buyer:buyer_id(*),
        seller:seller_id(*)
      ''').or('buyer_id.eq.$userId,seller_id.eq.$userId').order('last_message_at', ascending: false);

      return (data as List).map((json) => ChatModel.fromJson(json)).toList();
    } catch (e, st) {
      AppLogger.e('Error fetching chats', e, st);
      return [];
    }
  }

  Future<ChatModel?> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final existing = await client
          .from('chats')
          .select('''
            *,
            products(*, product_images(*)),
            buyer:buyer_id(*),
            seller:seller_id(*)
          ''')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .maybeSingle();

      if (existing != null) {
        return ChatModel.fromJson(existing);
      }

      final newChat = await client.from('chats').insert({
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'last_message': 'Chat started for transaction',
        'last_message_at': DateTime.now().toIso8601String(),
      }).select('''
        *,
        products(*, product_images(*)),
        buyer:buyer_id(*),
        seller:seller_id(*)
      ''').single();

      return ChatModel.fromJson(newChat);
    } catch (e, st) {
      AppLogger.e('Error in getOrCreateChat', e, st);
      return null;
    }
  }

  Stream<List<MessageModel>> streamChatMessages(String chatId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => MessageModel.fromJson(json)).toList());
  }

  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      await client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'message': message,
        'message_type': messageType,
      });

      await client.from('chats').update({
        'last_message': message,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      return true;
    } catch (e, st) {
      AppLogger.e('Error sending message', e, st);
      return false;
    }
  }

  // 11. Notifications & Watchlist
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final data = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e, st) {
      AppLogger.e('Error fetching notifications', e, st);
      return [];
    }
  }

  Future<List<String>> getWatchlistProductIds(String userId) async {
    try {
      final data = await client
          .from('watchlist')
          .select('product_id')
          .eq('user_id', userId);

      return (data as List).map((item) => item['product_id'] as String).toList();
    } catch (e, st) {
      AppLogger.e('Error fetching watchlist', e, st);
      return [];
    }
  }

  Future<bool> toggleWatchlist(String userId, String productId) async {
    try {
      final existing = await client
          .from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('watchlist')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
        return false;
      } else {
        await client.from('watchlist').insert({
          'user_id': userId,
          'product_id': productId,
        });
        return true;
      }
    } catch (e, st) {
      AppLogger.e('Error toggling watchlist', e, st);
      return false;
    }
  }

  // 12. Submit Report
  Future<bool> submitReport({
    required String reporterId,
    String? reportedUserId,
    String? productId,
    required String reason,
    String? description,
  }) async {
    try {
      await client.from('reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'product_id': productId,
        'reason': reason,
        'description': description ?? '',
        'status': 'PENDING',
      });
      return true;
    } catch (e, st) {
      AppLogger.e('Error submitting report', e, st);
      return false;
    }
  }
}
