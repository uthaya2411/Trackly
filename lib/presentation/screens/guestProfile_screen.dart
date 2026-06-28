import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';
import 'main_layout.dart';

class GuestProfileScreen extends ConsumerStatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  ConsumerState<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends ConsumerState<GuestProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _incomeController;
  late TextEditingController _savingsGoalController;

  String _selectedCurrency = '₹';
  final List<String> _currencies = ['₹', '\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _nameController = TextEditingController();
    _incomeController = TextEditingController();
    _savingsGoalController = TextEditingController();
  }

  @override
  void dispose() {
    // Crucial! Always dispose controllers to prevent memory leaks in mobile memory
    _nameController.dispose();
    _incomeController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // save currency globally across the app
    ref.read(expenseProvider.notifier).setCurrency(_selectedCurrency);
    ref.read(expenseProvider.notifier).completeOnboarding();

    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    final goal = double.tryParse(_savingsGoalController.text.trim()) ?? 0.0;
    // save data using river pod
    ref
        .read(expenseProvider.notifier)
        .saveGuestProfile(name: name, income: income, goal: goal);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get styles from theme
    final textTheme = Theme.of(context).textTheme;
    // 2. Read true dark mode state from our central Riverpod vault!
    final state = ref.watch(expenseProvider);

    final isDark = state.isDarkMode;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.ambientGlow),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.isFirebaseConnected
                        ? "Setup Secure Profile"
                        : "Setup Guest Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Hardcode to white for a quick test
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isFirebaseConnected
                        ? 'Configure your secure cloud account profile'
                        : 'Configure your guest profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Enter your name"
                                : null,
                            decoration: InputDecoration(
                              labelText: state.isFirebaseConnected ?"Profile Display Name" :"Guest Name",
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Select Base Currency',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _currencies.map((symbol) {
                              final isSelected = _selectedCurrency == symbol;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCurrency = symbol;
                                  });
                                },
                                child: Container(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white.withOpacity(0.08),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      symbol,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _incomeController,
                            keyboardType: TextInputType.number,

                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Enter your valid income"
                                : null,
                            decoration: InputDecoration(
                              labelText: "Monthly Income",
                              prefixIcon: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.income,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _savingsGoalController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Enter Your Saving Goals"
                                : null,
                            decoration: InputDecoration(
                              labelText: "Monthly Savings Goal",
                              prefixIcon: Icon(
                                Icons.track_changes_rounded,
                                color: AppColors.savings,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              _submitForm(); // Call our validation and saving logic!
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                child:  Center(
                                  child: Text(
                                    state.isFirebaseConnected
                                        ? "Create Account Setup"
                                        : "Create Sandbox Profile",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
