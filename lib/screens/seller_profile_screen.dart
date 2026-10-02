import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/profile_model.dart';

class SellerProfileScreen extends StatelessWidget {
  final ProfileModel seller;

  const SellerProfileScreen({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage(
                seller.profileImage ??
                    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=300&q=80',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  seller.name,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                if (seller.verificationStatus) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 20, color: AppTheme.accentEmerald),
                ],
              ],
            ),
            Text(
              seller.locationName,
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),

            const SizedBox(height: 24),

            // TRUST STATS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfileStat(
                      '⭐ ${seller.rating.toStringAsFixed(1)}', 'Rating'),
                  _buildProfileStat(
                      '${seller.completedTransactions}', 'Deals Completed'),
                  _buildProfileStat(
                      '${seller.bidReliability}%', 'Bid Reliability'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // VERIFICATION STATUS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust & Verification Badges',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.phone_android, color: AppTheme.accentEmerald),
                    title: Text('Phone Verified (OTP)'),
                    subtitle: Text('Identity matched with verified mobile number'),
                  ),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.email, color: AppTheme.accentIndigo),
                    title: Text('Email Verified'),
                    subtitle: Text('Primary contact address confirmed'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentAmber,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
