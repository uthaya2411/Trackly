import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_visa_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  String _selectedType = 'All'; // 'All', 'Income', 'Expense'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Calculate Financial Summary Metrics
    double totalIncome = state.monthlyIncome;
    double totalExpense = 0;

    for (final tx in state.transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;
    final now = DateTime.now();
    final filteredTransactions = state.transactions.where((tx) {
      final matchesSearch =
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType =
          _selectedType == 'All' ||
          (_selectedType == 'Income' && tx.type == TransactionType.income) ||
          (_selectedType == 'Expense' && tx.type == TransactionType.expense);
      return matchesSearch && matchesType;
    }).toList();

    final currentMonthYear =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentBudgets = state.budgets
        .where((b) => b.monthYear == currentMonthYear)
        .toList();
    final currentMonthExpenses = state.transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        110,
      ), // Extra bottom padding to clear floating nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Profile Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.activeUserEmail.isEmpty
                        ? 'Portfolio Guest'
                        : state.activeUserEmail.split('@').first,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Simulated Notification icon with active cloud sync indicator
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      ref
                          .read(expenseProvider.notifier)
                          .runCloudSyncSimulation();
                    },
                    icon: Icon(
                      Icons.cloud_done_rounded,
                      color: state.isFirebaseConnected
                          ? AppColors.secondary
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 26,
                    ),
                  ),
                  if (state.isSyncing)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.income,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Core Visual Card Block: The Platinum Fintech Visa Card
          PremiumVisaCard(
            netBalance: netBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            monthlyIncome: state.monthlyIncome,
            symbol: state.currencySymbol,
            email: state.activeUserEmail,
            textTheme: textTheme,
          ),
          const SizedBox(height: 28),

          // Row 2: Graph Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Velocity',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Recent Week',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.secondary : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Spending Velocity Graph Box
          GlassCard(
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
            child: SizedBox(
              height: 180,
              child: _buildVelocityChart(
                state.transactions,
                state.currencySymbol,
              ),
            ),
          ),
          const SizedBox(height: 28),

          if (currentBudgets.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Limits',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Monthly Progress',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.secondary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: currentBudgets.map((budget) {
                  final spent = currentMonthExpenses
                      .where((tx) => tx.category == budget.category)
                      .fold(0.0, (sum, tx) => sum + tx.amount);
                  final progress = budget.limitAmount > 0
                      ? spent / budget.limitAmount
                      : 0.0;
                  final barColor = progress >= 0.9
                      ? AppColors.expense
                      : (progress >= 0.7 ? AppColors.goal : AppColors.income);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              budget.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(spent, symbol: state.currencySymbol)} / ${CurrencyFormatter.format(budget.limitAmount, symbol: state.currencySymbol)} (${(progress * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: 0.0,
                            end: progress.clamp(0.0, 1.0),
                          ),
                          builder: (context, animValue, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: animValue,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                color: barColor,
                                minHeight: 8,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Row 3: Transaction List Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Swipe to delete',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: 16,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.search,
                  color: isDark
                      ? Colors.white.withOpacity(0.38)
                      : Colors.black.withOpacity(0.45),
                ),
                hintText: 'Search transactions...',
                hintStyle: TextStyle( 
                  color: isDark
                      ? Colors.white.withOpacity(0.38)
                      : Colors.black.withOpacity(0.45),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['All', 'Income', 'Expense'].map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Recent Activity Dismissible List
          if (filteredTransactions.isEmpty)
            _buildEmptyTransactionsPlaceholder(textTheme)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTransactions.length > 5
                  ? 5
                  : filteredTransactions.length,
              itemBuilder: (context, idx) {
                final tx = filteredTransactions[idx];
                return StaggeredListItem(
                  index: idx,
                  child: _buildTransactionItem(
                    tx,
                    state.currencySymbol,
                    ref,
                    context,
                    textTheme,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Line Chart representation of Spending velocity over the last 7 days
  Widget _buildVelocityChart(List<Transaction> transactions, String symbol) {
    final now = DateTime.now();
    final expenseTxs = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Map spending to the last 7 days dynamically
    final daysData = List.generate(7, (idx) {
      final day = now.subtract(Duration(days: 6 - idx));
      final totalForDay = expenseTxs
          .where(
            (t) =>
                t.date.day == day.day &&
                t.date.month == day.month &&
                t.date.year == day.year,
          )
          .fold(0.0, (sum, item) => sum + item.amount);
      return FlSpot(idx.toDouble(), totalForDay);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                AppColors.darkSurface.withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '$symbol${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),

        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ), // Clean uncluttered visual
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final day = now.subtract(Duration(days: 6 - val.toInt()));
                final formatter = DateFormat('E');
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formatter.format(day),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.38)
                          : Colors.black.withOpacity(0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: daysData,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.24),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dismissible Transaction row renderer
  Widget _buildTransactionItem(
    Transaction tx,
    String symbol,
    WidgetRef ref,
    BuildContext context,
    TextTheme textTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Choose icons & colors dynamically
    IconData catIcon;
    Color catColor;

    switch (tx.category) {
      case 'Food':
        catIcon = Icons.restaurant_rounded;
        catColor = AppColors.categoryFood;
        break;
      case 'Travel':
        catIcon = Icons.directions_car_rounded;
        catColor = AppColors.categoryTravel;
        break;
      case 'Bills':
        catIcon = Icons.receipt_long_rounded;
        catColor = AppColors.categoryBills;
        break;
      case 'Shopping':
        catIcon = Icons.shopping_bag_rounded;
        catColor = AppColors.categoryShopping;
        break;
      case 'Salary':
        catIcon = Icons.monetization_on_rounded;
        catColor = AppColors.categorySalary;
        break;
      case 'Investment':
        catIcon = Icons.trending_up_rounded;
        catColor = AppColors.categoryInvestment;
        break;
      default:
        catIcon = Icons.wallet_outlined;
        catColor = AppColors.primary;
    }

    final isIncome = tx.type == TransactionType.income;
    final dateString = DateFormat('MMM d, h:mm a').format(tx.date);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(expenseProvider.notifier).deleteTransaction(tx.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.expense.withOpacity(0.3)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.expense,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: 20,
          child: Row(
            children: [
              // Dynamic Category Icon Bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(isDark ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: catColor.withOpacity(0.24)),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateString,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.black.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount output tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount, symbol: symbol)}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (tx.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Has note',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsPlaceholder(TextTheme textTheme) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Colors.white30),
          const SizedBox(height: 14),
          Text(
            'No Recent Activity',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the "+" button below to log your transactions!',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white30,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Delayed trigger for stagger effect
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
