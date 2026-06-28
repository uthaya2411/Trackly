import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../providers/expense_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/add_transaction_modal.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  bool _isChecking = false;

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });
    // Artificial visual delay for premium feel
    await Future.delayed(const Duration(milliseconds: 1000));
    await ref.read(isOfflineProvider.notifier).forceCheck();
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  // The collection of child screens we switch between
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const BudgetScreen(),
    const SettingsScreen(),
  ];

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Let modal handle glass borders
      builder: (context) => const AddTransactionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final isOffline = ref.watch(isOfflineProvider) && ref.watch(expenseProvider).isFirebaseConnected;

    final Widget mainScaffold = Scaffold(
      extendBody:
          true, // Crucial! Allows body to extend under the floating glass nav bar
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned.fill(
            child: Container(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
            ),
          ),
          if (isDark)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.ambientGlow),
              ),
            ),

          // Render active screen
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),

      // Premium Centered Add Button floating
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Floating Rounded Glass Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  textTheme,
                ),
                _buildNavItem(1, Icons.bar_chart_rounded, 'Reports', textTheme),
                const SizedBox(
                  width: 48,
                ), // Spacer for center Docked Floating Action Button
                _buildNavItem(
                  2,
                  Icons.track_changes_rounded,
                  'Budgets',
                  textTheme,
                ),
                _buildNavItem(3, Icons.settings_rounded, 'Settings', textTheme),
              ],
            ),
          ),
        ),
      ),
    );

    if (isOffline) {
      return Scaffold(
        body: Stack(
          children: [
            IgnorePointer(child: mainScaffold),
            Positioned.fill(
              child: Container(
                color: isDark
                    ? Colors.black.withOpacity(0.65)
                    : Colors.black.withOpacity(0.35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(28.0),
                  borderRadius: 28,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.12),
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connection Lost',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Trackly Pro requires an active internet connection to sync your dashboard and process transactions. Please verify your network settings.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _checkConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Check Connection',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

    return mainScaffold;
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    TextTheme textTheme,
  ) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.08))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4)),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
