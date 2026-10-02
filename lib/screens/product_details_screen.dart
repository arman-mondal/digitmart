import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../providers/auction_provider.dart';
import '../models/bid_model.dart';
import '../services/supabase_service.dart';
import 'chat_details_screen.dart';
import 'report_screen.dart';
import 'seller_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuctionProvider>(context, listen: false)
          .loadProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auctionProv = Provider.of<AuctionProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final product = auctionProv.currentProduct;
    final auction = auctionProv.auction;
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (auctionProv.isLoading || product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentAmber),
        ),
      );
    }

    final isWatched = appState.watchlistIds.contains(product.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              isWatched ? Icons.bookmark : Icons.bookmark_border,
              color: isWatched ? AppTheme.accentAmber : AppTheme.textLight,
            ),
            onPressed: () {
              appState.toggleWatchlist(product.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Banner & Gallery
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.network(
                product.images.isNotEmpty
                    ? product.images.first
                    : 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Mode Badges & Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.sellingMode == 'FIX_AND_BID'
                              ? AppTheme.accentIndigo
                              : (product.sellingMode == 'BID'
                                  ? AppTheme.accentAmber
                                  : AppTheme.accentEmerald),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.sellingMode == 'FIX_AND_BID'
                              ? 'FIX + BID'
                              : product.sellingMode,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: product.sellingMode == 'BID'
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Text(
                          product.condition,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        product.location,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    product.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. LIVE AUCTION TIMER CARD (If Auction)
                  if (auction != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: auction.isEndingSoon
                              ? [const Color(0xFF450A0A), const Color(0xFF1E1B4B)]
                              : [AppTheme.primaryLight, AppTheme.cardDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: auction.isEndingSoon
                              ? AppTheme.accentRose
                              : AppTheme.accentAmber.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled,
                                    color: auction.isEndingSoon
                                        ? AppTheme.accentRose
                                        : AppTheme.accentAmber,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    auction.isExpired
                                        ? 'AUCTION ENDED'
                                        : (auction.isEndingSoon
                                            ? 'ENDING SOON'
                                            : 'AUCTION TIMER'),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: auction.isEndingSoon
                                          ? AppTheme.accentRose
                                          : AppTheme.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${auction.totalBids} Total Bids',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeBox(
                                  _formatTwoDigits(
                                      auctionProv.remainingTime.inHours),
                                  'HRS'),
                              _buildTimeSeparator(),
                              _buildTimeBox(
                                  _formatTwoDigits(auctionProv
                                      .remainingTime.inMinutes
                                      .remainder(60)),
                                  'MIN'),
                              _buildTimeSeparator(),
                              _buildTimeBox(
                                  _formatTwoDigits(auctionProv
                                      .remainingTime.inSeconds
                                      .remainder(60)),
                                  'SEC'),
                            ],
                          ),
                          if (auction.status == 'ENDING' ||
                              auction.extendedUntil != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentIndigo.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⚡ Anti-Snipe Extension Active (+2 mins added)',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. BID & PRICE DISPLAY BOX
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      children: [
                        if (auction != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Bid',
                                    style: GoogleFonts.outfit(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    currencyFormatter
                                        .format(auction.currentPrice),
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.accentEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Min Increment',
                                    style: GoogleFonts.outfit(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    '+ ${currencyFormatter.format(auction.minimumIncrement)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: AppTheme.borderDark, height: 24),
                        ],

                        // ACTION BUTTONS
                        Row(
                          children: [
                            if (auction != null) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.gavel,
                                      color: Colors.black),
                                  label: Text(
                                    'BID ${currencyFormatter.format(auction.currentPrice + auction.minimumIncrement)}',
                                  ),
                                  onPressed: () {
                                    _showBidDialog(
                                        context, auctionProv, currencyFormatter);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],

                            if (auction?.buy_now_price != null ||
                                product.sellingMode == 'FIX') ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppTheme.accentIndigo,
                                    side: BorderSide.none,
                                  ),
                                  icon: const Icon(Icons.flash_on,
                                      color: Colors.white),
                                  label: Text(
                                    'BUY NOW ${currencyFormatter.format(auction?.buy_now_price ?? 38500)}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final res = await auctionProv.executeBuyNow(
                                        appState.currentProfile!.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message']),
                                          backgroundColor:
                                              AppTheme.accentEmerald,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. SELLER TRUST & RELIABILITY CARD
                  if (product.seller != null) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerProfileScreen(
                                seller: product.seller!),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(
                                      product.seller!.profileImage ??
                                          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=300&q=80'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            product.seller!.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified,
                                              size: 16,
                                              color: AppTheme.accentEmerald),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14,
                                              color: AppTheme.accentAmber),
                                          Text(
                                            ' ${product.seller!.rating.toStringAsFixed(1)} / 5.0 • ',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: AppTheme.textMuted),
                                          ),
                                          Text(
                                            '${product.seller!.completedTransactions} completed',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: AppTheme.textMuted),
                              ],
                            ),
                            const Divider(color: AppTheme.borderDark, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTrustStat(
                                    'Bid Reliability',
                                    '${product.seller!.bidReliability}%',
                                    AppTheme.accentEmerald),
                                _buildTrustStat(
                                    'Phone Verified', '✓ Yes', AppTheme.accentAmber),
                                _buildTrustStat(
                                    'Email Verified', '✓ Yes', AppTheme.accentIndigo),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. CHAT WITH SELLER CTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppTheme.accentAmber),
                      label: const Text('Chat Direct with Seller'),
                      onPressed: () async {
                        final chat = await _service.getOrCreateChat(
                          productId: product.id,
                          buyerId: appState.currentProfile!.id,
                          sellerId: product.sellerId,
                        );

                        if (chat != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailsScreen(chat: chat),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 7. DESCRIPTION
                  Text(
                    'Description',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 8. BID HISTORY LIST
                  if (auction != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bid History',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          '${auctionProv.bids.length} bids placed',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (auctionProv.bids.isEmpty)
                      Text(
                        'No bids placed yet. Be the first to bid!',
                        style: GoogleFonts.outfit(color: AppTheme.textMuted),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: auctionProv.bids.length,
                        itemBuilder: (context, index) {
                          final bid = auctionProv.bids[index];
                          return _buildBidRow(bid, index == 0, currencyFormatter);
                        },
                      ),
                  ],

                  const SizedBox(height: 24),

                  // 9. REPORT BUTTON
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.flag_outlined,
                          size: 16, color: AppTheme.textMuted),
                      label: Text(
                        'Report suspicious listing',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(
                              reportedUserId: product.sellerId,
                              productId: product.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textLight,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.accentAmber,
        ),
      ),
    );
  }

  Widget _buildTrustStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildBidRow(
      BidModel bid, bool isWinning, NumberFormat currencyFormatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinning
            ? AppTheme.accentEmerald.withOpacity(0.1)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning ? AppTheme.accentEmerald : AppTheme.borderDark,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    isWinning ? AppTheme.accentEmerald : AppTheme.borderDark,
                child: Text(
                  bid.bidder?.name.substring(0, 1) ?? 'B',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bid.bidder?.name ?? 'Bidder',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  if (bid.isAutoBid)
                    Text(
                      '⚡ Auto-bid',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: AppTheme.accentAmber),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (isWinning) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'WINNING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                currencyFormatter.format(bid.amount),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isWinning ? AppTheme.accentEmerald : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBidDialog(BuildContext context, AuctionProvider auctionProv,
      NumberFormat formatter) {
    final auction = auctionProv.auction!;
    final minNextBid = auction.currentPrice + auction.minimumIncrement;
    final TextEditingController bidAmountCtrl =
        TextEditingController(text: minNextBid.toStringAsFixed(0));
    final TextEditingController maxAutoBidCtrl = TextEditingController();
    bool enableAutoBid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Place Your Bid',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimum next bid is ${formatter.format(minNextBid)}',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: bidAmountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Your Bid Amount (₹)',
                      prefixText: '₹ ',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppTheme.accentAmber),
                        onPressed: () {
                          final currentVal =
                              double.tryParse(bidAmountCtrl.text) ?? minNextBid;
                          bidAmountCtrl.text = (currentVal + auction.minimumIncrement)
                              .toStringAsFixed(0);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto Bid Toggle
                  SwitchListTile(
                    activeColor: AppTheme.accentAmber,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Automatic Bidding',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, color: AppTheme.textLight),
                    ),
                    subtitle: Text(
                      'Set your max threshold. We automatically bid for you up to max bid keeping it private.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    value: enableAutoBid,
                    onChanged: (val) {
                      setModalState(() {
                        enableAutoBid = val;
                      });
                    },
                  ),

                  if (enableAutoBid) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxAutoBidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Auto-Bid Limit (₹)',
                        prefixText: '₹ ',
                        hintText: 'e.g. 35000',
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final bidVal =
                            double.tryParse(bidAmountCtrl.text) ?? minNextBid;
                        final maxVal = enableAutoBid
                            ? double.tryParse(maxAutoBidCtrl.text)
                            : null;

                        final appState = Provider.of<AppStateProvider>(
                            context,
                            listen: false);

                        final res = await auctionProv.placeBid(
                          bidderId: appState.currentProfile!.id,
                          bidAmount: bidVal,
                          maxAutoBid: maxVal,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message']),
                              backgroundColor: res['success'] == true
                                  ? AppTheme.accentEmerald
                                  : AppTheme.accentRose,
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm & Submit Bid'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');
}
