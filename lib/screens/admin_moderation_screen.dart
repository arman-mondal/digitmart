import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'rep-001',
      'reason': 'Suspicious Bidding',
      'user': 'Bikram Roy (Reliability: 94%)',
      'item': 'MacBook Air M2',
      'status': 'PENDING',
      'details': 'Placed bid but stopped responding to seller.'
    },
    {
      'id': 'rep-002',
      'reason': 'Fake listing attempt',
      'user': 'Anonymous User',
      'item': 'iPhone 13 (Price ₹10,000)',
      'status': 'INVESTIGATING',
      'details': 'Unusual pricing compared to market value.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Moderation Center'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentRose,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'ADMIN',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Summary Metrics
            Row(
              children: [
                _buildAdminStat('Pending Reports', '${_reports.length}', AppTheme.accentRose),
                const SizedBox(width: 12),
                _buildAdminStat('Bans Active', '3', AppTheme.accentAmber),
                const SizedBox(width: 12),
                _buildAdminStat('Listings Audited', '142', AppTheme.accentEmerald),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Flagged Reports & Moderation Queue',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),

            const SizedBox(height: 12),

            ..._reports.map((r) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.cardDark,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRose.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r['reason'],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentRose,
                              ),
                            ),
                          ),
                          Text(
                            r['status'],
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppTheme.accentAmber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reported User: ${r['user']}',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight),
                      ),
                      Text(
                        'Target Item: ${r['item']}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r['details'],
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const Divider(color: AppTheme.borderDark, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentAmber,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Warning issued to user.')),
                              );
                            },
                            child: const Text('Issue Warning'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentRose,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              setState(() {
                                r['status'] = 'RESOLVED / SUSPENDED';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'User suspended and listing removed.')),
                              );
                            },
                            child: const Text('Suspend Account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStat(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
