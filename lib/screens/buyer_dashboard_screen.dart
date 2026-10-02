import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import 'product_details_screen.dart';

class BuyerDashboardScreen extends StatelessWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buyer Dashboard'),
          bottom: TabBar(
            indicatorColor: AppTheme.accentAmber,
            labelColor: AppTheme.accentAmber,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(text: 'Active Bids'),
              Tab(text: 'Won Auctions'),
              Tab(text: 'Watchlist'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: ACTIVE BIDS
            _buildActiveBidsTab(context, appState, currencyFormatter),

            // TAB 2: WON AUCTIONS
            _buildWonAuctionsTab(context, appState, currencyFormatter),

            // TAB 3: WATCHLIST
            _buildWatchlistTab(context, appState, currencyFormatter),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBidsTab(
      BuildContext context, AppStateProvider appState, NumberFormat formatter) {
    final activeBiddedProducts = appState.products
        .where((p) => p.isAuction && p.auction != null)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeBiddedProducts.length,
      itemBuilder: (context, index) {
        final product = activeBiddedProducts[index];
        final auction = product.auction!;
        final isWinning = index == 0; // Arman is top bidder on index 0 (iPhone 14)

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWinning ? AppTheme.accentEmerald : AppTheme.accentRose,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.images.isNotEmpty
                          ? product.images.first
                          : 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=300&q=80',
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isWinning
                                    ? AppTheme.accentEmerald
                                    : AppTheme.accentRose,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isWinning
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 12,
                                    color: isWinning ? Colors.black : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isWinning ? '🟢 WINNING' : '🔴 OUTBID',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isWinning
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${auction.totalBids} bids',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Max: ${formatter.format(isWinning ? 30000 : 45000)}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Text(
                              'Current: ${formatter.format(auction.currentPrice)}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isWinning
                                    ? AppTheme.accentEmerald
                                    : AppTheme.accentRose,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderDark, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          size: 14, color: AppTheme.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in 02:14:32',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      backgroundColor: isWinning
                          ? AppTheme.primaryLight
                          : AppTheme.accentAmber,
                      foregroundColor:
                          isWinning ? AppTheme.textLight : Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailsScreen(productId: product.id),
                        ),
                      );
                    },
                    child: Text(isWinning ? 'View Auction' : 'Bid Again'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWonAuctionsTab(
      BuildContext context, AppStateProvider appState, NumberFormat formatter) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentEmerald),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🏆 AUCTION WON',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Won on 02 Oct 2026',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?auto=format&fit=crop&w=300&q=80',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PlayStation 5 Disc Edition',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Winning Bid: ₹32,500',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderDark, height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.black),
                  label: const Text('Contact Seller to Arrange Meetup'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Chat with Seller...'),
                        backgroundColor: AppTheme.accentIndigo,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistTab(
      BuildContext context, AppStateProvider appState, NumberFormat formatter) {
    final watchedProducts = appState.products
        .where((p) => appState.watchlistIds.contains(p.id))
        .toList();

    if (watchedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Your Watchlist is Empty',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: watchedProducts.length,
      itemBuilder: (context, index) {
        final product = watchedProducts[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(productId: product.id),
              ),
            );
          },
          leading: Image.network(
            product.images.first,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(
            product.title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: AppTheme.textLight),
          ),
          subtitle: Text(product.location),
          trailing: IconButton(
            icon: const Icon(Icons.bookmark, color: AppTheme.accentAmber),
            onPressed: () => appState.toggleWatchlist(product.id),
          ),
        );
      },
    );
  }
}
