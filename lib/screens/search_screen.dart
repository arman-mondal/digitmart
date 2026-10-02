import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/product_model.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSort;

  const SearchScreen({super.key, this.initialSort});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';
  String _selectedMode = 'ALL';
  String _selectedDistance = '10 km';

  @override
  void initState() {
    super.initState();
    if (widget.initialSort == 'ENDING_SOON') {
      _selectedMode = 'BID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    List<ProductModel> filtered = appState.products.where((p) {
      if (_selectedCategory != 'all' && p.categoryId != _selectedCategory) {
        return false;
      }
      if (_selectedMode != 'ALL' && p.sellingMode != _selectedMode) {
        return false;
      }
      if (_searchCtrl.text.isNotEmpty) {
        final query = _searchCtrl.text.toLowerCase();
        return p.title.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: GoogleFonts.outfit(color: AppTheme.textLight),
          decoration: const InputDecoration(
            hintText: 'Search iPhone, MacBook, PS5, Camera...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchCtrl.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTERS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primaryLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown(
                    label: 'Mode',
                    value: _selectedMode,
                    items: {
                      'ALL': 'All Modes',
                      'FIX_AND_BID': 'Fix + Bid',
                      'BID': 'Auction Only',
                      'FIX': 'Fixed Price'
                    },
                    onChanged: (val) => setState(() => _selectedMode = val!),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterDropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: {
                      'all': 'All Categories',
                      'phones': 'Phones',
                      'laptops': 'Laptops',
                      'gaming': 'Gaming',
                      'cameras': 'Cameras'
                    },
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterDropdown(
                    label: 'Radius',
                    value: _selectedDistance,
                    items: {
                      '5 km': 'Within 5 km',
                      '10 km': 'Within 10 km',
                      '25 km': 'Within 25 km'
                    },
                    onChanged: (val) => setState(() => _selectedDistance = val!),
                  ),
                ],
              ),
            ),
          ),

          // RESULTS LIST
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No products found matching filters',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                  productId: product.id),
                            ),
                          );
                        },
                        leading: Image.network(
                          product.images.isNotEmpty
                              ? product.images.first
                              : 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=300&q=80',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          product.title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight),
                        ),
                        subtitle: Text(
                          '${product.sellingMode} • ${product.location}',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: Text(
                          product.auction != null
                              ? currencyFormatter
                                  .format(product.auction!.currentPrice)
                              : currencyFormatter.format(38500),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.cardDark,
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
          items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
