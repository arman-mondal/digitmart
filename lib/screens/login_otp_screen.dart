import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/supabase_service.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _service = SupabaseService();

  // Sign In Controllers
  final _signInEmailCtrl = TextEditingController(text: 'arman@fixorbid.com');
  final _signInPasswordCtrl = TextEditingController(text: 'Password123!');

  // Sign Up Controllers
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();
  final _signUpLocationCtrl =
      TextEditingController(text: 'New Town, Kolkata');

  bool _isLoading = false;

  final List<Map<String, String>> _demoProfiles = [
    {
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'Arman Sharma (Buyer & Seller)',
      'phone': '+91 9876543210',
      'role': 'Active Buyer (Top bidder on iPhone 14)'
    },
    {
      'id': '22222222-2222-2222-2222-222222222222',
      'name': 'Rahul Verma (Seller)',
      'phone': '+91 9830012345',
      'role': 'Seller of iPhone 14 (32 completed transactions)'
    },
    {
      'id': '33333333-3333-3333-3333-333333333333',
      'name': 'Priya Patel (Seller)',
      'phone': '+91 9811122334',
      'role': 'Seller of MacBook Air M2 & PS5'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix or Bid Account Sign In'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentAmber,
          labelColor: AppTheme.accentAmber,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Email Sign In'),
            Tab(text: 'Create Account'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: SIGN IN
                  Column(
                    children: [
                      TextField(
                        controller: _signInEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon:
                              Icon(Icons.email, color: AppTheme.accentAmber),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _signInPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                              Icon(Icons.lock, color: AppTheme.accentAmber),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    final res = await _service.signInWithEmail(
                                      email: _signInEmailCtrl.text.trim(),
                                      password:
                                          _signInPasswordCtrl.text.trim(),
                                    );
                                    if (res.user != null) {
                                      await appState
                                          .loadUserProfile(res.user!.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Signed in successfully with Supabase Auth!'),
                                            backgroundColor:
                                                AppTheme.accentEmerald,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Auth error: $e'),
                                        backgroundColor: AppTheme.accentRose,
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text('Sign In with Email'),
                        ),
                      ),
                    ],
                  ),

                  // TAB 2: SIGN UP
                  Column(
                    children: [
                      TextField(
                        controller: _signUpNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon:
                              Icon(Icons.person, color: AppTheme.accentAmber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _signUpEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon:
                              Icon(Icons.email, color: AppTheme.accentAmber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _signUpPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                              Icon(Icons.lock, color: AppTheme.accentAmber),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_signUpEmailCtrl.text.isEmpty ||
                                      _signUpPasswordCtrl.text.isEmpty) {
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    final res = await _service.signUpWithEmail(
                                      email: _signUpEmailCtrl.text.trim(),
                                      password:
                                          _signUpPasswordCtrl.text.trim(),
                                      name: _signUpNameCtrl.text.trim(),
                                      phone: _signUpPhoneCtrl.text.trim(),
                                      locationName: _signUpLocationCtrl.text.trim(),
                                    );
                                    if (res.user != null) {
                                      await appState
                                          .loadUserProfile(res.user!.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Account created successfully in Supabase!'),
                                            backgroundColor:
                                                AppTheme.accentEmerald,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sign up error: $e'),
                                        backgroundColor: AppTheme.accentRose,
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          child: const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.borderDark)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                ),
                const Expanded(child: Divider(color: AppTheme.borderDark)),
              ],
            ),
            const SizedBox(height: 16),

            // GOOGLE OAUTH BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.accentIndigo),
                ),
                icon: const Icon(Icons.g_mobiledata,
                    size: 28, color: AppTheme.accentIndigo),
                label: Text(
                  'Continue with Google Auth',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final success = await _service.signInWithGoogle();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Initiated Google OAuth flow...')),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: AppTheme.borderDark),
            const SizedBox(height: 16),

            Text(
              'QUICK DEMO WALKTHROUGH PROFILES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentAmber,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            ..._demoProfiles.map((p) {
              final isCurrent = appState.currentProfile?.id == p['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isCurrent ? AppTheme.primaryLight : AppTheme.cardDark,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isCurrent ? AppTheme.accentAmber : AppTheme.borderDark,
                    child: Icon(
                      Icons.person,
                      color: isCurrent ? Colors.black : AppTheme.textLight,
                    ),
                  ),
                  title: Text(
                    p['name']!,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  subtitle: Text(
                    p['role']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.accentEmerald)
                      : TextButton(
                          onPressed: () async {
                            await appState.switchDemoUser(p['id']!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Switched active profile to ${p['name']}'),
                                  backgroundColor: AppTheme.accentIndigo,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Switch'),
                        ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
