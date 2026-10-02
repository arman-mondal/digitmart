import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/auction_model.dart';
import '../models/bid_model.dart';
import '../services/supabase_service.dart';
import '../services/auction_engine.dart';

class AuctionProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  final AuctionEngine _engine = AuctionEngine();

  ProductModel? _currentProduct;
  List<BidModel> _bids = [];
  bool _isLoading = false;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  ProductModel? get currentProduct => _currentProduct;
  AuctionModel? get auction => _currentProduct?.auction;
  List<BidModel> get bids => _bids;
  bool get isLoading => _isLoading;
  Duration get remainingTime => _remainingTime;

  Future<void> loadProductDetails(String productId) async {
    _isLoading = true;
    notifyListeners();

    _currentProduct = await _service.getProductDetails(productId);
    if (_currentProduct?.auction != null) {
      _bids = await _service.getAuctionBids(_currentProduct!.auction!.id);
      _startTimer();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (auction == null) return;

    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (auction == null) return;
    final now = DateTime.now();
    final end = auction!.effectiveEndTime;
    if (end.isAfter(now)) {
      _remainingTime = end.difference(now);
    } else {
      _remainingTime = Duration.zero;
      _countdownTimer?.cancel();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> placeBid({
    required String bidderId,
    required double bidAmount,
    double? maxAutoBid,
  }) async {
    if (auction == null) {
      return {'success': false, 'message': 'No active auction.'};
    }

    final res = await _engine.placeBid(
      auctionId: auction!.id,
      bidderId: bidderId,
      bidAmount: bidAmount,
      maxAutoBidAmount: maxAutoBid,
    );

    if (res['success'] == true) {
      await loadProductDetails(_currentProduct!.id);
    }

    return res;
  }

  Future<Map<String, dynamic>> executeBuyNow(String buyerId) async {
    if (auction == null || auction!.buy_now_price == null) {
      return {'success': false, 'message': 'Buy Now not available'};
    }

    final res = await _engine.processBuyNow(
      auctionId: auction!.id,
      productId: _currentProduct!.id,
      buyerId: buyerId,
      buyNowPrice: auction!.buy_now_price!,
    );

    if (res['success'] == true) {
      await loadProductDetails(_currentProduct!.id);
    }

    return res;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
