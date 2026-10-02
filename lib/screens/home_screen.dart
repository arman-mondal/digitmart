import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/product_model.dart';
import 'product_details_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'login_otp_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppTheme.accentAmber),
                const SizedBox(width: 4),
                Text(
                  appState.currentProfile?.locationName ?? 'New Town, Kolkata',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: AppTheme.textMuted),
              ],
            ),
            Text(
              'Within 10 km • Direct Peer-to-Peer',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: AppTheme.textLight),
                if (appState.unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentRose,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${appState.unreadNotificationsCount}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginOtpScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentAmber,
                backgroundImage: appState.currentProfile?.profileImage != null
                    ? NetworkImage(appState.currentProfile!.profileImage!)
                    : null,
                child: appState.currentProfile?.profileImage == null
                    ? const Icon(Icons.person, size: 18, color: Colors.black)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshProducts(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar Trigger
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.accentAmber),
                      const SizedBox(width: 12),
                      Text(
                        'Search iPhone, MacBook, PS5, Camera...',
                        style: GoogleFonts.outfit(
                            color: AppTheme.textMuted, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.tune_rounded, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Peer-to-Peer Concept Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF31103F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'FIX OR BID',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'No Platform Fees • Direct Meetup',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Discover → Bid / Buy → Chat → Meet',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect directly with verified local buyers & sellers.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Mode Selection Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'ALL', 'All Deals', appState),
                    _buildFilterChip(context, 'FIX_AND_BID', 'Fix + Bid', appState),
                    _buildFilterChip(context, 'BID', 'Auctions Only', appState),
                    _buildFilterChip(context, 'FIX', 'Buy Now (Fixed)', appState),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 4. 🔥 ENDING SOON AUCTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'Ending Soon',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen(
                                initialSort: 'ENDING_SOON')),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.outfit(color: AppTheme.accentAmber),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (appState.isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.accentAmber),
                ))
              else ...[
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: appState.products
                        .where((p) => p.isAuction && p.auction != null)
                        .length,
                    itemBuilder: (context, index) {
                      final auctionProducts = appState.products
                          .where((p) => p.isAuction && p.auction != null)
                          .toList();
                      final product = auctionProducts[index];
                      return _buildEndingSoonCard(
                          context, product, currencyFormatter);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // 5. 🏆 ALL LISTINGS & POPULAR AUCTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 Featured Marketplace',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    '${appState.products.length} Items',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.products.length,
                itemBuilder: (context, index) {
                  final product = appState.products[index];
                  return _buildMarketplaceItemCard(
                      context, product, currencyFormatter);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String modeKey, String label,
      AppStateProvider provider) {
    final isSelected = provider.selectedSellingMode == modeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            provider.setSellingMode(modeKey);
          }
        },
        selectedColor: AppTheme.accentAmber,
        backgroundColor: AppTheme.cardDark,
        labelStyle: GoogleFonts.outfit(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : AppTheme.textLight,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.accentAmber : AppTheme.borderDark,
        ),
      ),
    );
  }

  Widget _buildEndingSoonCard(
      BuildContext context, ProductModel product, NumberFormat formatter) {
    final auction = product.auction!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.images.isNotEmpty
                        ? product.images.first
                        : 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=400&q=80',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Ending Soon',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${auction.totalBids} bids',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentAmber),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.location,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid',
                            style: GoogleFonts.outfit(
                                fontSize: 10, color: AppTheme.textMuted),
                          ),
                          Text(
                            formatter.format(auction.currentPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BID',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceItemCard(
      BuildContext context, ProductModel product, NumberFormat formatter) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.images.isNotEmpty
                      ? product.images.first
                      : 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=300&q=80',
                  height: 95,
                  width: 95,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.sellingMode == 'FIX_AND_BID'
                                ? AppTheme.accentIndigo
                                : (product.sellingMode == 'BID'
                                    ? AppTheme.accentAmber
                                    : AppTheme.accentEmerald),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.sellingMode == 'FIX_AND_BID'
                                ? 'FIX + BID'
                                : product.sellingMode,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: product.sellingMode == 'BID'
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.condition,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          product.location,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.auction != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Bid (${product.auction!.totalBids} bids)',
                                style: GoogleFonts.outfit(
                                    fontSize: 10, color: AppTheme.textMuted),
                              ),
                              Text(
                                formatter.format(product.auction!.currentPrice),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentEmerald,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fixed Price',
                                style: GoogleFonts.outfit(
                                    fontSize: 10, color: AppTheme.textMuted),
                              ),
                              Text(
                                formatter.format(38500),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentAmber,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppTheme.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
