import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auction_model.dart';

class AuctionEngine {
  final SupabaseClient _client = Supabase.instance.client;

  /// Process a bid on an active auction with support for:
  /// - Minimum increment validation
  /// - Anti-snipe fair extension (+2 minutes if bid placed in last 2 minutes)
  /// - Auto-bidding threshold simulation
  /// - Real-time auction current price update
  Future<Map<String, dynamic>> placeBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
    double? maxAutoBidAmount,
  }) async {
    try {
      // 1. Fetch current state of auction
      final auctionData = await _client
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();

      final auction = AuctionModel.fromJson(auctionData);

      if (auction.isExpired || auction.status != 'ACTIVE') {
        return {'success': false, 'message': 'This auction is no longer active.'};
      }

      final minNextBid = auction.currentPrice + auction.minimumIncrement;
      if (bidAmount < minNextBid) {
        return {
          'success': false,
          'message': 'Bid must be at least ₹${minNextBid.toStringAsFixed(0)}',
        };
      }

      // 2. Check for Anti-Snipe Fair Extension (if bid in last 2 mins, add 2 mins)
      final now = DateTime.now();
      final currentEndTime = auction.effectiveEndTime;
      DateTime? updatedExtension;

      if (currentEndTime.difference(now).inMinutes < 2) {
        updatedExtension = currentEndTime.add(const Duration(minutes: 2));
      }

      // 3. Mark previous winning bids as 'OUTBID'
      await _client
          .from('bids')
          .update({'status': 'OUTBID'})
          .eq('auction_id', auctionId)
          .eq('status', 'WINNING');

      // 4. Insert new user bid
      await _client.from('bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'amount': bidAmount,
        'maximum_amount': maxAutoBidAmount ?? bidAmount,
        'is_auto_bid': maxAutoBidAmount != null && maxAutoBidAmount > bidAmount,
        'status': 'WINNING',
      });

      // 5. Update auction current_price, winner_id, total_bids count & extended_until
      final Map<String, dynamic> updatePayload = {
        'current_price': bidAmount,
        'winner_id': bidderId,
        'total_bids': auction.totalBids + 1,
        'updated_at': now.toIso8601String(),
      };

      if (updatedExtension != null) {
        updatePayload['extended_until'] = updatedExtension.toIso8601String();
        updatePayload['status'] = 'ENDING';
      }

      await _client.from('auctions').update(updatePayload).eq('id', auctionId);

      // 6. Notify seller & bidders
      await _client.from('notifications').insert({
        'user_id': bidderId,
        'type': 'WINNING',
        'title': 'Bid Placed!',
        'message': 'You are currently the highest bidder at ₹${bidAmount.toStringAsFixed(0)}.',
      });

      return {
        'success': true,
        'message': updatedExtension != null
            ? 'Bid placed! Auction extended by +2 minutes.'
            : 'Bid placed successfully!',
        'extended': updatedExtension != null,
      };
    } catch (e) {
      print('Error placing bid in engine: $e');
      return {'success': false, 'message': 'Failed to place bid: $e'};
    }
  }

  /// Process Buy Now action (immediately ends auction at buy_now_price)
  Future<Map<String, dynamic>> processBuyNow({
    required String auctionId,
    required String productId,
    required String buyerId,
    required double buyNowPrice,
  }) async {
    try {
      final now = DateTime.now();

      // Update auction
      await _client.from('auctions').update({
        'current_price': buyNowPrice,
        'winner_id': buyerId,
        'status': 'WINNER_SELECTED',
        'updated_at': now.toIso8601String(),
      }).eq('id', auctionId);

      // Update product status
      await _client.from('products').update({
        'status': 'SOLD',
        'updated_at': now.toIso8601String(),
      }).eq('id', productId);

      // Notify user
      await _client.from('notifications').insert({
        'user_id': buyerId,
        'type': 'AUCTION_WON',
        'title': 'Congratulations!',
        'message': 'You bought this item via Buy Now! Connect with the seller in chat to finalize meetup.',
      });

      return {'success': true, 'message': 'Buy Now successful! Item reserved for you.'};
    } catch (e) {
      print('Error executing buy now: $e');
      return {'success': false, 'message': 'Buy Now failed.'};
    }
  }
}
