import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackly/presentation/screens/onboarding_screen.dart';
import '../../core/constants/colors.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<String> _currenciesList = ['\$', '€', '£', '₹', '¥'];
  final ScrollController _terminalScrollController = ScrollController();

  void _scrollToBottom() {
    if (_terminalScrollController.hasClients) {
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _confirmEraseAll() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            SizedBox(width: 12),
            Text(
              'Security Wipe',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This will wipe all transactions, custom budget caps, and settings, and restore defaults. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white30),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(expenseProvider.notifier).resetAll();

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Wipe All Data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await ref.read(expenseProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    try {
      await ref.read(expenseProvider.notifier).deleteAccount();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Delete account failed: $e';
        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          msg = 'Security check: Please sign out, sign back in, and try deleting your account again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(
    String currentName,
    double currentIncome,
    double currentGoal,
  ) {
    final nameController = TextEditingController(text: currentName);
    final incomeController = TextEditingController(
      text: currentIncome.toStringAsFixed(0),
    );
    final goalController = TextEditingController(
      text: currentGoal.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit Sandbox Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Profile Guest Name',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: incomeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Montly Income Inflow',
                  prefixIcon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.income,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: goalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Montly Savings Target',
                  prefixIcon: Icon(
                    Icons.track_changes_rounded,
                    color: AppColors.savings,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white30),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newIncome =
                  double.tryParse(incomeController.text.trim()) ??
                  currentIncome;
              final newGoal =
                  double.tryParse(goalController.text.trim()) ?? currentGoal;
              if (newName.isNotEmpty) {
                ref
                    .read(expenseProvider.notifier)
                    .saveGuestProfile(
                      name: newName,
                      income: newIncome,
                      goal: newGoal,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sandbox profile updated successfully'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text("Update Profile"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll terminal log to bottom during cloud sync simulation
    if (state.isSyncing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Titles
          Text(
            'System Control',
            style: textTheme.displayMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PREFERENCES, CLOUD SYNC & CONFIGURATIONS',
            style: textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // User Profile Card Header
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Email & Status details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.activeUserEmail.isEmpty
                            ? 'Sandbox Guest Account'
                            : state.activeUserEmail,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: state.isFirebaseConnected
                                  ? AppColors.income
                                  : AppColors.goal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.isFirebaseConnected
                                ? 'SECURE FIREBASE ACTIVE'
                                : 'LOCAL OFFLINE SANDBOX',
                            style: TextStyle(
                              color: state.isFirebaseConnected
                                  ? AppColors.income
                                  : AppColors.goal,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state.guestName.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _showEditProfileDialog(
                        state.guestName,
                        state.monthlyIncome,
                        state.savingsGoal,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Preferences Settings Card
          Text(
            'Theme & Locale Preferences',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Dark mode Switcher Row
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'AMOLED Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'True black scaffolding to reduce battery draft',
                    style: TextStyle(
                      fontSize: 11,
                      color: state.isDarkMode ? Colors.white30 : Colors.black45,
                    ),
                  ),
                  trailing: Switch(
                    value: state.isDarkMode,
                    onChanged: (_) {
                      ref.read(expenseProvider.notifier).toggleTheme();
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1, indent: 56),

                // Currency Symbol Selector Row
                ListTile(
                  leading: const Icon(
                    Icons.monetization_on_rounded,
                    color: AppColors.secondary,
                  ),
                  title: const Text(
                    'Global Currency Unit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Format money inputs and visual graphs',
                    style: TextStyle(
                      fontSize: 11,
                      color: state.isDarkMode ? Colors.white30 : Colors.black45,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: state.currencySymbol,
                    dropdownColor: AppColors.darkSurface,
                    underline: const SizedBox(),
                    items: _currenciesList.map((String sym) {
                      return DropdownMenuItem<String>(
                        value: sym,
                        child: Text(
                          sym,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        ref.read(expenseProvider.notifier).setCurrency(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Firebase Cloud Sync Terminal Block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Firebase Database Syncer',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: state.isFirebaseConnected
                      ? AppColors.income.withOpacity(0.12)
                      : AppColors.goal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.isFirebaseConnected ? 'SYNCED' : 'UNBUFFERED',
                  style: TextStyle(
                    color: state.isFirebaseConnected
                        ? AppColors.income
                        : AppColors.goal,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom monospaced Terminal container
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF030408),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Terminal Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18.5),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F56),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFBD2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27C93F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'root@trackly:~/sync-engine',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.white30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Terminal Logs Output Scroll View
                Expanded(
                  child: ListView.builder(
                    controller: _terminalScrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: state.syncLogs.isEmpty
                        ? 1
                        : state.syncLogs.length,
                    itemBuilder: (context, idx) {
                      if (state.syncLogs.isEmpty) {
                        return const Text(
                          '\$ sync-engine --status=ready\n[INFO] Offline buffer ready. Tap "Synchronize Nodes" to buffer databases...',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        );
                      }

                      return Text(
                        state.syncLogs[idx],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.secondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Synchronize button trigger
          GestureDetector(
            onTap: state.isSyncing
                ? null
                : () => ref
                      .read(expenseProvider.notifier)
                      .runCloudSyncSimulation(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.cyanGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Synchronize Firebase Nodes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Danger maintenance heading
          Text(
            'Maintenance & Security',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isFirebaseConnected) ...[
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _handleSignOut();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.expense,
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _handleDeleteAccount();
              },
            ),
            const SizedBox(height: 12),
          ],
          // Erase all data tile
          GestureDetector(
            onTap: _confirmEraseAll,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 18,
              customColor: AppColors.expense.withOpacity(0.04),
              customBorder: Border.all(
                color: AppColors.expense.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perform Complete Wipe',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Permanently wipe SharedPreferences local-first cache and restore seeds.',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black45,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white30,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
