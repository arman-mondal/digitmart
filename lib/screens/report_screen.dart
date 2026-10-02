import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/supabase_service.dart';

class ReportScreen extends StatefulWidget {
  final String? reportedUserId;
  final String? productId;

  const ReportScreen({
    super.key,
    this.reportedUserId,
    this.productId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final SupabaseService _service = SupabaseService();
  final _descCtrl = TextEditingController();
  String _selectedReason = 'Fake listing';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Fake listing',
    'Scam or Fraud attempt',
    'Counterfeit product',
    'Suspicious bidding manipulation',
    'Harassment or Spam',
    'Auction abandonment',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue / User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Abuse or Fake Listing',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our moderation team reviews reports within 24 hours to keep Fix or Bid safe.',
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(labelText: 'Reason for Report'),
              dropdownColor: AppTheme.cardDark,
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Details',
                hintText: 'Provide any specific context or details...',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRose,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        final success = await _service.submitReport(
                          reporterId: appState.currentProfile!.id,
                          reportedUserId: widget.reportedUserId,
                          productId: widget.productId,
                          reason: _selectedReason,
                          description: _descCtrl.text,
                        );
                        setState(() => _isSubmitting = false);

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted successfully.'),
                              backgroundColor: AppTheme.accentEmerald,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
