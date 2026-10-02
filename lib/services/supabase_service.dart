import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/profile_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  // Active default user ID fallback for quick walkthrough demo
  static const String demoUserId = '11111111-1111-1111-1111-111111111111';

  User? get currentUser => client.auth.currentUser;

  // 1. SUPABASE AUTHENTICATION
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
    String locationName = 'New Town, Kolkata',
  }) async {
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
      // Upsert profile record in public.profiles
      await client.from('profiles').upsert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'phone': phone,
        'location_name': locationName,
        'verification_status': true,
        'rating': 5.0,
        'completed_transactions': 0,
        'bid_reliability': 100,
      });
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      final res = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.fixorbid.fix_or_bid://login-callback',
      );
      return res;
    } catch (e) {
      print('Google OAuth error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // 2. Fetch User Profile
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response != null) {
        return ProfileModel.fromJson(response);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  // 3. Fetch Products with images, auctions, and seller details
  Future<List<ProductModel>> getProducts({
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

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // 4. Fetch Single Product Details
  Future<ProductModel?> getProductDetails(String productId) async {
    try {
      final data = await client.from('products').select('''
        *,
        product_images(*),
        auctions(*),
        profiles:seller_id(*)
      ''').eq('id', productId).single();

      return ProductModel.fromJson(data);
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  // 5. Fetch Bids for an Auction
  Future<List<BidModel>> getAuctionBids(String auctionId) async {
    try {
      final data = await client.from('bids').select('''
        *,
        profiles:bidder_id(*)
      ''').eq('auction_id', auctionId).order('amount', ascending: false);

      return (data as List).map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching bids: $e');
      return [];
    }
  }

  // 6. Create New Listing
  Future<String?> createProductListing({
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
        'status': 'ACTIVE',
      }).select().single();

      final productId = productRes['id'] as String;

      // Add product image
      await client.from('product_images').insert({
        'product_id': productId,
        'image_url': imageUrl,
        'sort_order': 1,
      });

      // If Auction or Fix+Bid, create auction record
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

      return productId;
    } catch (e) {
      print('Error creating listing: $e');
      return null;
    }
  }

  // 7. Fetch Chats for User
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final data = await client.from('chats').select('''
        *,
        products(*, product_images(*)),
        buyer:buyer_id(*),
        seller:seller_id(*)
      ''').or('buyer_id.eq.$userId,seller_id.eq.$userId').order('last_message_at', ascending: false);

      return (data as List).map((json) => ChatModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  // 8. Get or Create Chat between buyer and seller
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

      // Create new chat
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
    } catch (e) {
      print('Error in getOrCreateChat: $e');
      return null;
    }
  }

  // 9. REALTIME MESSAGES STREAM & SEND MESSAGE
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
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // 10. Fetch Notifications
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
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // 11. Watchlist Management
  Future<List<String>> getWatchlistProductIds(String userId) async {
    try {
      final data = await client
          .from('watchlist')
          .select('product_id')
          .eq('user_id', userId);

      return (data as List).map((item) => item['product_id'] as String).toList();
    } catch (e) {
      print('Error fetching watchlist: $e');
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
    } catch (e) {
      print('Error toggling watchlist: $e');
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
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }
}
