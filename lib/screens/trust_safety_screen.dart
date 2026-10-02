import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';

class TrustSafetyScreen extends StatelessWidget {
  const TrustSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profile = appState.currentProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Trust & Safety System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER SCORE SUMMARY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, size: 40, color: AppTheme.accentEmerald),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Bid Reliability',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            '${profile?.bidReliability ?? 98}% Excellent',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (profile?.bidReliability ?? 98) / 100,
                    backgroundColor: Colors.black26,
                    color: AppTheme.accentEmerald,
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'How Fix or Bid Protects Users',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 12),

            _buildRuleCard(
              icon: Icons.gavel,
              title: 'Bid Reliability Score',
              desc:
                  'Users who win auctions but abandon transactions suffer reliability penalties. Low scores result in bidding restrictions or account suspension.',
            ),

            _buildRuleCard(
              icon: Icons.phonelink_ring,
              title: 'Mandatory Phone Verification',
              desc:
                  'Every active bidder and seller is verified via SMS OTP before placing bids or creating listings.',
            ),

            _buildRuleCard(
              icon: Icons.handshake_outlined,
              title: 'Direct Peer-to-Peer Transactions',
              desc:
                  'Fix or Bid does not process payments or deliver goods. Buyers inspect products in person before paying sellers directly.',
            ),

            _buildRuleCard(
              icon: Icons.report_problem_outlined,
              title: 'Community Moderation & Reporting',
              desc:
                  'Flag suspicious listings or fake bids anytime. Our admin system reviews flags instantly to maintain platform integrity.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accentAmber, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
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
}
