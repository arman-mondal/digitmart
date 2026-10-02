import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/supabase_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final SupabaseService _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fixedPriceCtrl = TextEditingController();
  final _startingPriceCtrl = TextEditingController(text: '15000');
  final _minIncrementCtrl = TextEditingController(text: '500');
  final _reservePriceCtrl = TextEditingController();
  final _buyNowCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController(
    text: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
  );

  String _selectedCategory = 'phones';
  String _selectedCondition = 'Like New';
  String _selectedLocation = 'New Town, Kolkata';
  String _sellingMode = 'FIX_AND_BID'; // 'FIX', 'BID', 'FIX_AND_BID'
  int _durationHours = 24;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'id': 'phones', 'name': 'Phones & Mobile'},
    {'id': 'laptops', 'name': 'Laptops & Computers'},
    {'id': 'gaming', 'name': 'Gaming & Consoles'},
    {'id': 'cameras', 'name': 'Cameras & Photography'},
    {'id': 'audio', 'name': 'Audio & Headphones'},
    {'id': 'watches', 'name': 'Smartwatches & Accessories'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Post New Listing')),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentAmber),
                  SizedBox(height: 16),
                  Text('Publishing your listing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selling Mode',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Selling Mode Segmented Switch
                    Row(
                      children: [
                        _buildModeTile('FIX_AND_BID', 'Fix + Bid', Icons.electric_bolt),
                        const SizedBox(width: 8),
                        _buildModeTile('BID', 'Auction Only', Icons.gavel),
                        const SizedBox(width: 8),
                        _buildModeTile('FIX', 'Fixed Price', Icons.sell),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Product Information
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Title',
                        hintText: 'e.g. iPhone 14 Pro Max 256GB Deep Purple',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter title' : null,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            dropdownColor: AppTheme.cardDark,
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c['id'],
                                child: Text(c['name']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCondition,
                            decoration:
                                const InputDecoration(labelText: 'Condition'),
                            dropdownColor: AppTheme.cardDark,
                            items: ['New', 'Like New', 'Used - Good', 'Used - Fair']
                                .map((cond) => DropdownMenuItem(
                                      value: cond,
                                      child: Text(cond),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCondition = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Describe condition, included accessories, warranty details, meetup preference...',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter description' : null,
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Approximate Location (City / Area)',
                        prefixIcon:
                            Icon(Icons.location_on, color: AppTheme.accentAmber),
                      ),
                      dropdownColor: AppTheme.cardDark,
                      items: [
                        'New Town, Kolkata',
                        'Salt Lake, Kolkata',
                        'Park Street, Kolkata',
                        'Ballygunge, Kolkata',
                      ]
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLocation = val);
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderDark),
                    const SizedBox(height: 16),

                    // PRICING DETAILS ACCORDING TO SELLING MODE
                    if (_sellingMode == 'FIX') ...[
                      TextFormField(
                        controller: _fixedPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fixed Selling Price (₹)',
                          prefixText: '₹ ',
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter price' : null,
                      ),
                    ],

                    if (_sellingMode == 'BID' ||
                        _sellingMode == 'FIX_AND_BID') ...[
                      Text(
                        'Auction & Bidding Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startingPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Starting Bid (₹)',
                                prefixText: '₹ ',
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter start bid'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _minIncrementCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Increment (₹)',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _reservePriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Reserve Price (Optional ₹)',
                                prefixText: '₹ ',
                                hintText: 'Hidden minimum',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _buyNowCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Buy Now Price (Optional ₹)',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _durationHours,
                        decoration: const InputDecoration(
                          labelText: 'Auction Duration',
                          prefixIcon:
                              Icon(Icons.timer, color: AppTheme.accentAmber),
                        ),
                        dropdownColor: AppTheme.cardDark,
                        items: [
                          const DropdownMenuItem(
                              value: 12, child: Text('12 Hours')),
                          const DropdownMenuItem(
                              value: 24, child: Text('24 Hours (Recommended)')),
                          const DropdownMenuItem(
                              value: 48, child: Text('48 Hours')),
                          const DropdownMenuItem(
                              value: 72, child: Text('3 Days')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _durationHours = val);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Photo Image URL',
                        prefixIcon: Icon(Icons.image, color: AppTheme.accentAmber),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.publish, color: Colors.black),
                        label: const Text('Publish Product Listing'),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSubmitting = true);

                            final productId =
                                await _service.createProductListing(
                              sellerId: appState.currentProfile!.id,
                              title: _titleCtrl.text.trim(),
                              description: _descCtrl.text.trim(),
                              categoryId: _selectedCategory,
                              condition: _selectedCondition,
                              location: _selectedLocation,
                              sellingMode: _sellingMode,
                              imageUrl: _imageUrlCtrl.text.trim(),
                              fixedPrice:
                                  double.tryParse(_fixedPriceCtrl.text),
                              startingPrice:
                                  double.tryParse(_startingPriceCtrl.text),
                              minIncrement:
                                  double.tryParse(_minIncrementCtrl.text),
                              reservePrice:
                                  double.tryParse(_reservePriceCtrl.text),
                              buyNowPrice: double.tryParse(_buyNowCtrl.text),
                              durationHours: _durationHours,
                            );

                            setState(() => _isSubmitting = false);

                            if (productId != null && context.mounted) {
                              await appState.refreshProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Listing published successfully!'),
                                  backgroundColor: AppTheme.accentEmerald,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModeTile(String modeKey, String label, IconData icon) {
    final isSelected = _sellingMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sellingMode = modeKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentAmber : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.accentAmber : AppTheme.borderDark,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.black : AppTheme.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
