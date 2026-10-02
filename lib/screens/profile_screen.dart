import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import 'admin_moderation_screen.dart';
import 'login_otp_screen.dart';
import 'trust_safety_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profile = appState.currentProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('My Account & Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.accentAmber,
              backgroundImage: profile?.profileImage != null
                  ? NetworkImage(profile!.profileImage!)
                  : null,
              child: profile?.profileImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.black)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile?.name ?? (appState.isAuthenticated ? 'User' : 'Guest'),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                if (profile?.verificationStatus == true) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 20, color: AppTheme.accentEmerald),
                ],
              ],
            ),
            Text(
              profile?.locationName ?? 'Kolkata, West Bengal',
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),

            const SizedBox(height: 24),

            // RELIABILITY & RATING BANNER
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
                  _buildStatTile(
                      '⭐ ${profile?.rating.toStringAsFixed(1) ?? "5.0"}',
                      'Rating'),
                  _buildStatTile(
                      '${profile?.bidReliability ?? 100}%', 'Bid Reliability'),
                  _buildStatTile(
                      '${profile?.completedTransactions ?? 0}', 'Completed Deals'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!appState.isAuthenticated) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.black),
                  label: const Text('Sign In or Register'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginOtpScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // SETTINGS & MENU LIST
            _buildMenuItem(
              icon: Icons.shield_outlined,
              title: 'Trust & Safety Center',
              subtitle: 'Bid reliability score rules & safety tips',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrustSafetyScreen()),
                );
              },
            ),

            if (profile?.isAdmin == true) ...[
              _buildMenuItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin Moderation Center',
                subtitle: 'Review flagged listings & manage suspensions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminModerationScreen()),
                  );
                },
              ),
            ],

            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'How Fix or Bid Works',
              subtitle: 'Fix vs Bid • Peer-to-Peer direct transactions',
              onTap: () {
                _showHowItWorksDialog(context);
              },
            ),

            if (appState.isAuthenticated) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRose,
                    side: const BorderSide(color: AppTheme.accentRose),
                  ),
                  icon: const Icon(Icons.logout, color: AppTheme.accentRose),
                  label: const Text('Sign Out'),
                  onPressed: () async {
                    await appState.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out successfully.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 18,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardDark,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.accentAmber),
        title: Text(
          title,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: AppTheme.textLight),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Fix or Bid Architecture'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. DISCOVER local items.'),
            Text('2. FIX (Set Price) or BID (Compete).'),
            Text('3. CHAT direct with buyer/seller.'),
            Text('4. CONNECT & Meetup locally.'),
            SizedBox(height: 12),
            Text(
              'Fix or Bid does not process payments or delivery. Complete transactions independently.',
              style: TextStyle(color: AppTheme.accentAmber, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
