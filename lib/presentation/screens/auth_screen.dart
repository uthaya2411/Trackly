import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';
import 'guestProfile_screen.dart';
import 'main_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'recruiter.portfolio@trackly.pro',
  );
  final _passwordController = TextEditingController(text: 'demo1234');
  bool _isSignUp = false;
  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Future<void> _handleGuestFresh() async {
  //   await ref.read(expenseProvider.notifier).startGuestFresh();
  //   _navigateToMain();
  // }
  Future<void> _handleGuestFresh() async {
    // 1. Initialize the fresh guest setup state
    await ref.read(expenseProvider.notifier).startGuestFresh();

    // 2. Navigate smoothly to your new Guest Profile Screen!
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GuestProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  Future<void> _handleGuestDemo() async {
    await ref.read(expenseProvider.notifier).startGuestDemo();
    _navigateToMain();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainLayout(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      if (_isSignUp) {
        await ref
            .read(expenseProvider.notifier)
            .signUpWithEmail(email, password);
        _navigateToProfileSetup();
      } else {
        await ref
            .read(expenseProvider.notifier)
            .signInWithEmail(email, password);
        // Check for backup on Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          final hasBackup = await ref
              .read(expenseProvider.notifier)
              .hasFireStoreBackup(user.email ?? '');

          if (hasBackup) {
            // We will define this dialog function in the next step
            _showBackupPromptDialog(user.email ?? '');
          } else {
            // No cloud backup. If we have local transactions, back them up automatically!
            final state = ref.read(expenseProvider);
            if (state.transactions.isNotEmpty) {
              await ref
                  .read(expenseProvider.notifier)
                  .syncAllDataToFirestore(user.email ?? '');
              _navigateToMain();
            } else {
              _navigateToProfileSetup();
            }
          }
        }
      }
    } catch (e) {
      String msg = 'Error: $e';
      if (e.toString().toLowerCase().contains('network')) {
        msg = 'No internet connection. Please check your connection and try again.';
      } else if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-credential':
            msg = 'Invalid email or password. Please check your credentials or register a new account.';
            break;
          case 'user-not-found':
            msg = 'No account found with this email. Please register first.';
            break;
          case 'wrong-password':
            msg = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            msg = 'Please enter a valid email address.';
            break;
          case 'email-already-in-use':
            msg = 'This email is already in use. Please sign in instead.';
            break;
          case 'weak-password':
            msg = 'The password is too weak. Please choose a stronger password.';
            break;
          default:
            msg = e.message ?? 'Authentication failed. Please try again.';
        }
      } else {
        final errorStr = e.toString();
        if (errorStr.contains('invalid-credential')) {
          msg = 'Invalid email or password. Please check your credentials or register a new account.';
        } else if (errorStr.contains('user-not-found')) {
          msg = 'No account found with this email. Please register first.';
        } else if (errorStr.contains('wrong-password')) {
          msg = 'Incorrect password. Please try again.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBackupPromptDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isLoading = ref.watch(expenseProvider);
            return WillPopScope(
              onWillPop: () async => false, // Disable back button
              child: AlertDialog(
                backgroundColor:
                    Colors.transparent, // We will use glass card styling
                contentPadding: EdgeInsets.zero,

                // We will build the dialog content here next...
                content: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      Center(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: const Icon(
                            Icons.cloud_download_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        'Cloud Backup Detected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        'We found an existing transaction and budget ledger on Firestore. Would you like to restore your secure backup or start as fresh?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // We will add the buttons here next...
                      // Button 1: Restore Cloud Backup
                      GestureDetector(
                        onTap: isLoading.isSyncing
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(expenseProvider.notifier)
                                      .restoreBackupFromFirestore(email);
                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // Close dialog
                                    _navigateToMain();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Restore failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.premiumGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: isLoading.isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Restore Cloud Backup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Button 2: Start Fresh
                      // Button 2: Start Fresh
                      GestureDetector(
                        onTap: isLoading.isSyncing
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(expenseProvider.notifier)
                                      .clearFirestoreBackup(email);
                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // Close dialog
                                    _navigateToProfileSetup();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to clear backup: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: isLoading.isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                : const Text(
                                    'Start as Fresh',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (isLoading.transactions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: isLoading.isSyncing
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(expenseProvider.notifier)
                                        .mergeLocalDataWithFirestore(email);
                                    if (context.mounted) {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Close dialog
                                      _navigateToMain();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Merge failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.income.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.income.withOpacity(0.4),
                              ),
                            ),
                            child: Center(
                              child: isLoading.isSyncing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.income,
                                      ),
                                    )
                                  : const Text(
                                      'Merge Sandbox Data',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.income,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final success = await ref
          .read(expenseProvider.notifier)
          .signInWithGoogle();
      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          final hasBackup = await ref
              .read(expenseProvider.notifier)
              .hasFireStoreBackup(user.email ?? '');

          if (hasBackup) {
            _showBackupPromptDialog(user.email ?? '');
          } else {
            _navigateToProfileSetup();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase().contains('network')
            ? 'No internet connection. Please check your connection and try again.'
            : 'Google Sign-In failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GuestProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background ambient glows
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.ambientGlow),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Slogan
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 18,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.wallet_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isSignUp
                          ? 'Create Portfolio Account'
                          : 'Welcome to Trackly Pro',
                      style: textTheme.displayMedium?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SECURE HYBRID DATA INFRASTRUCTURE',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Auth Form Card
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'REGISTER' : 'LOG IN',
                              style: textTheme.labelLarge?.copyWith(
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: textTheme.bodyMedium,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(val.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },

                              decoration: const InputDecoration(
                                labelText: 'Corporate Email Address',
                                hintText: 'recruiter.portfolio@trackly.pro',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: textTheme.bodyMedium,
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Password Pin',
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            GestureDetector(
                              onTap: state.isSyncing ? null : _handleAuth,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppColors.premiumGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: state.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isSignUp ? 'Sign Up' : 'Sign In',
                                          style: textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In Card
                    OutlinedButton.icon(
                      onPressed: state.isSyncing ? null : _handleGoogleSignIn,
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: Text(
                        'Authenticate with Google',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        backgroundColor: Colors.white.withOpacity(0.02),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle Sign-up/Sign-in text
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Sign Up",
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Recruiter Sandbox Shortcut (Try as Guest)
                    // Dual-Action Recruiter Sandbox Shortcut Card (Try as Guest)
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flash_on_rounded,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Try as Guest (Local Sandbox)',
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Explore with zero commitments',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Button 1: Start Fresh (Clean Rupee Ledger)
                          GestureDetector(
                            onTap: state.isSyncing ? null : _handleGuestFresh,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.emeraldGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.income.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: state.isSyncing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Guest: Start Fresh (₹ Rupee)',
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 13.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Button 2: Load Demo (Pre-seeded Ledger)
                          GestureDetector(
                            onTap: state.isSyncing ? null : _handleGuestDemo,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: state.isSyncing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Guest: Explore Seeded Demo',
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
