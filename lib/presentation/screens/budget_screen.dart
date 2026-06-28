import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/budget.dart';
import '../../data/models/transaction.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  // Global Savings Goal target
  double _savingsTarget = 50000.00;

  void _showAdjustGoalDialog(double currentGoal) {
    final currencySymbol = ref.read(expenseProvider).currencySymbol;
    final controller = TextEditingController(
      text: currentGoal.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Adjust Savings Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set your monthly net surplus targets:',
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Goal amount',
                prefixText: '$currencySymbol ',
              ),
            ),
          ],
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
            onPressed: () {
              final newGoal = double.tryParse(controller.text) ?? currentGoal;
              final state = ref.read(expenseProvider);

              if (state.guestName.isNotEmpty) {
                ref
                    .read(expenseProvider.notifier)
                    .saveGuestProfile(
                      name: state.guestName,
                      income: state.monthlyIncome,
                      goal: newGoal,
                    );
              } else {
                setState(() {
                  _savingsTarget = newGoal;
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Target',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustBudgetDialog(String category, double currentLimit) {
    final currencySymbol = ref.read(expenseProvider).currencySymbol;
    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Adjust $category Budget',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set maximum monthly expense limit for $category:',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.38)
                    : Colors.black.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maximum Budget Cap',
                prefixText: '$currencySymbol ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.38)
                    : Colors.black.withOpacity(0.45),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? currentLimit;
              ref.read(expenseProvider.notifier).setBudget(category, newLimit);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Cap',
              style: TextStyle(color: Colors.white),
            ),
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

    // 1. Calculate Monthly Cash Flow metrics
    final now = DateTime.now();
    final currentMonthTxs = state.transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    double totalIncome = state.monthlyIncome;
    double totalExpense = 0;

    for (final tx in currentMonthTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final netSavings = totalIncome - totalExpense;
    final savingsTarget = state.savingsGoal > 0
        ? state.savingsGoal
        : _savingsTarget;

    final savingsProgress = savingsTarget > 0
        ? (netSavings / savingsTarget).clamp(0.0, 1.0)
        : 0.0;

    // Default categories list that the user can set caps on
    final listCategories = [
      'Food',
      'Travel',
      'Bills',
      'Shopping',
      'Investment',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header titles
          Text(
            'Wealth Ceilings',
            style: textTheme.displayMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'BUDGET CONTROLS & NET SURPLUS GOALS',
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

          // Savings Target Ring progress card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppColors.premiumGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.24),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GlassCard(
              borderRadius: 24,
              customColor: Colors.black.withOpacity(0.12),
              customBorder: Border.all(color: Colors.white.withOpacity(0.08)),
              child: Row(
                children: [
                  // Circular Progress Indicator representing Savings Target progress
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: savingsProgress,
                            strokeWidth: 7,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.savings,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(savingsProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Goal details text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET SAVINGS TARGET',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(netSavings, symbol: state.currencySymbol)} / ${CurrencyFormatter.format(savingsTarget, symbol: state.currencySymbol)}',
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          netSavings >= savingsTarget
                              ? '🏆 Milestone surplus target unlocked!'
                              : 'Keep logging transactions to complete goal!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Goal pencil adjustments trigger
                  IconButton(
                    onPressed: () => _showAdjustGoalDialog(savingsTarget),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Core Budget lists headings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budget Caps',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Month MTD',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.secondary : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories Limits List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listCategories.length,
            itemBuilder: (context, idx) {
              final catName = listCategories[idx];

              // Find matching budget in state (or build default mockup)
              final budget = state.budgets.firstWhere(
                (b) => b.category == catName,
                orElse: () => Budget(
                  category: catName,
                  limitAmount: 300.0,
                  monthYear: '',
                ),
              );

              // Calculate MTD spent in this category
              final spent = currentMonthTxs
                  .where(
                    (t) =>
                        t.category == catName &&
                        t.type == TransactionType.expense,
                  )
                  .fold(0.0, (sum, item) => sum + item.amount);

              return _buildBudgetProgressTile(
                budget,
                spent,
                state.currencySymbol,
                context,
                textTheme,
              );
            },
          ),
        ],
      ),
    );
  }

  // Budgets progress row widget renderer
  Widget _buildBudgetProgressTile(
    Budget budget,
    double spent,
    String symbol,
    BuildContext context,
    TextTheme textTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = budget.calculateProgress(spent);

    // Determine state warning colorations dynamically
    Color statusColor;
    String statusLabel;

    if (progress >= 1.0) {
      statusColor = AppColors.expense;
      statusLabel = 'OVERSPENT';
    } else if (progress >= 0.8) {
      statusColor = AppColors.goal;
      statusLabel = 'WARNING';
    } else {
      statusColor = AppColors.income;
      statusLabel = 'HEALTHY';
    }

    IconData catIcon;
    switch (budget.category) {
      case 'Food':
        catIcon = Icons.restaurant_rounded;
        break;
      case 'Travel':
        catIcon = Icons.directions_car_rounded;
        break;
      case 'Bills':
        catIcon = Icons.receipt_long_rounded;
        break;
      case 'Shopping':
        catIcon = Icons.shopping_bag_rounded;
        break;
      case 'Investment':
        catIcon = Icons.trending_up_rounded;
        break;
      default:
        catIcon = Icons.wallet_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 20,
        customBorder: progress >= 0.8
            ? Border.all(color: statusColor.withOpacity(0.24), width: 1.2)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Header category name, caps status badge, edit button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    budget.category,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAdjustBudgetDialog(
                    budget.category,
                    budget.limitAmount,
                  ),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Spent details text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${CurrencyFormatter.format(spent, symbol: symbol)}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Cap: ${CurrencyFormatter.format(budget.limitAmount, symbol: symbol)}',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.black.withOpacity(0.4),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Neon progress slider
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
