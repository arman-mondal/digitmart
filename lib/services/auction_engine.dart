import 'supabase_service.dart';

class AuctionEngine {
  final SupabaseService _service = SupabaseService();

  /// Process a bid using server-side RPC `place_bid` (SECURITY DEFINER with row lock)
  Future<Map<String, dynamic>> placeBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
    double? maxAutoBidAmount,
  }) async {
    final result = await _service.placeBidRpc(
      auctionId: auctionId,
      amount: bidAmount,
      maxAmount: maxAutoBidAmount,
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      return {'success': false, 'message': result.errorMessage ?? 'Failed to place bid'};
    }
  }

  /// Process Buy Now action using server-side RPC `buy_now`
  Future<Map<String, dynamic>> processBuyNow({
    required String auctionId,
    required String productId,
    required String buyerId,
    required double buyNowPrice,
  }) async {
    final result = await _service.buyNowRpc(auctionId);

    if (result.isSuccess) {
      return result.data!;
    } else {
      return {'success': false, 'message': result.errorMessage ?? 'Buy Now failed'};
    }
  }
}
