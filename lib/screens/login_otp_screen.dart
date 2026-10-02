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
  final _signInEmailCtrl = TextEditingController();
  final _signInPasswordCtrl = TextEditingController();

  // Sign Up Controllers
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();
  final _signUpLocationCtrl =
      TextEditingController(text: 'Kolkata, West Bengal');

  bool _isLoading = false;

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
        title: const Text('Fix or Bid Sign In'),
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
              height: 330,
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
                                  if (_signInEmailCtrl.text.isEmpty ||
                                      _signInPasswordCtrl.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Enter email and password.')),
                                    );
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    final res = await _service.signInWithEmail(
                                      email: _signInEmailCtrl.text.trim(),
                                      password:
                                          _signInPasswordCtrl.text.trim(),
                                    );
                                    if (res.isSuccess && res.data?.user != null) {
                                      await appState
                                          .loadUserProfile(res.data!.user!.id);
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
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(res.errorMessage ?? 'Sign in failed'),
                                            backgroundColor: AppTheme.accentRose,
                                          ),
                                        );
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
                                    if (res.isSuccess && res.data?.user != null) {
                                      await appState
                                          .loadUserProfile(res.data!.user!.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Account created successfully!'),
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

            const SizedBox(height: 16),
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
            const SizedBox(height: 20),

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
          ],
        ),
      ),
    );
  }
}
