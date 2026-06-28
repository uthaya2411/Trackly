import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../data/models/transaction.dart';
import '../../data/models/ai_insight.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedFilterIndex = 1; // 0 = Week, 1 = Month, 2 = Year
  bool _isExporting = false;
  int _touchedPieIndex = -1;

  Future<void> _exportPdfReport() async {
    setState(() => _isExporting = true);

    final state = ref.read(expenseProvider);

    // Smooth delay for visual premium feel
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      await PdfExporter.generateAndShareReport(
        transactions: state.transactions,
        budgets: state.budgets,
        currencySymbol: state.currencySymbol,
        monthlyIncome: state.monthlyIncome,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compile PDF: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions by selected range
    final filteredTxs = _getFilteredTransactions(state.transactions);

    // Get rules-based computed AI insights
    final aiInsights = ref.watch(expenseProvider.notifier).aiInsights;

    // Group expenses by category
    final categoryTotals = _getCategoryTotals(filteredTxs);
    final totalExpense = categoryTotals.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen Title
          Text(
            'Financial Intelligence',
            style: textTheme.displayMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'COGNITIVE SPENDING SUMMARY & AUDIT',
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

          // Horizontal Filter Chips
          Row(
            children: [
              _buildFilterChip(0, 'Weekly'),
              const SizedBox(width: 10),
              _buildFilterChip(1, 'Monthly'),
              const SizedBox(width: 10),
              _buildFilterChip(2, 'Yearly'),
            ],
          ),
          const SizedBox(height: 24),

          // Main Interactive Donut Graph Card
          EntranceAnimator(
            delay: Duration.zero,
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Expense Allocation',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (totalExpense == 0)
                    _buildNoExpensesWidget(textTheme)
                  else ...[
                    Row(
                      children: [
                        // Donut Chart
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 140,
                            child: _buildDonutChart(
                              categoryTotals,
                              totalExpense,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Legend Indicator Column
                        Expanded(
                          flex: 6,
                          child: _buildLegendColumn(
                            categoryTotals,
                            totalExpense,
                            state.currencySymbol,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Double Bar Comparison Chart Card
          EntranceAnimator(
            delay: const Duration(milliseconds: 150),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Weekly Balance Comparison',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: _buildDualBarChart(state.transactions),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Smart Projections card
          EntranceAnimator(
            delay: const Duration(milliseconds: 300),
            child: _buildProjectionsCard(
              state.transactions,
              state.currencySymbol,
              textTheme,
              state.monthlyIncome,
            ),
          ),
          const SizedBox(height: 28),

          // Rules-Based AI spending advice header
          Text(
            'Smart Recommendations',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic AI Insights list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: aiInsights.length,
            itemBuilder: (context, idx) {
              final insight = aiInsights[idx];
              return _buildInsightItem(insight, context, textTheme);
            },
          ),
          const SizedBox(height: 24),

          // PDF Report Export trigger deck
          GestureDetector(
            onTap: _isExporting ? null : _exportPdfReport,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.premiumGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isExporting
                                ? 'Compiling Statement...'
                                : 'Generate PDF Statement',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compile corporate-grade ledger and analysis reports',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.share_rounded,
                      color: AppColors.secondary,
                      size: 20,
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

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Visual Donut Chart builder
  Widget _buildDonutChart(
    Map<String, double> categoryTotals,
    double totalExpense,
  ) {
    final List<PieChartSectionData> sections = [];
    int idx = 0;

    final Map<String, Color> catColors = {
      'Food': AppColors.categoryFood,
      'Travel': AppColors.categoryTravel,
      'Bills': AppColors.categoryBills,
      'Shopping': AppColors.categoryShopping,
      'Salary': AppColors.categorySalary,
      'Investment': AppColors.categoryInvestment,
    };

    categoryTotals.forEach((cat, value) {
      final isTouched = idx == _touchedPieIndex;
      final radius = isTouched ? 44.0 : 36.0;
      final percentage = (value / totalExpense) * 100;
      sections.add(
        PieChartSectionData(
          color: catColors[cat] ?? AppColors.primary,
          value: value,
          title: isTouched
              ? '${percentage.toStringAsFixed(1)}%'
              : '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 12 : 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
      );
      idx++;
    });

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedPieIndex = -1;
                return;
              }
              _touchedPieIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 4,
        centerSpaceRadius: 36,
        borderData: FlBorderData(show: false),
        sections: sections,
      ),
    );
  }

  // Category Legend Column layout
  Widget _buildLegendColumn(
    Map<String, double> categoryTotals,
    double totalExpense,
    String symbol,
  ) {
    final isDark =
        Theme.of(context).brightness ==
        Brightness.dark; // <--- Add this line here
    final Map<String, Color> catColors = {
      'Food': AppColors.categoryFood,
      'Travel': AppColors.categoryTravel,
      'Bills': AppColors.categoryBills,
      'Shopping': AppColors.categoryShopping,
      'Salary': AppColors.categorySalary,
      'Investment': AppColors.categoryInvestment,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: categoryTotals.entries.map((entry) {
        final percentage = (entry.value / totalExpense) * 100;
        final color = catColors[entry.key] ?? AppColors.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Inflow vs Outflow Dual Bar Chart Builder
  Widget _buildDualBarChart(List<Transaction> transactions) {
    final now = DateTime.now();

    final isDark =
        Theme.of(context).brightness ==
        Brightness.dark; // <--- Add this line here

    // Sum details over the past 4 weeks dynamically
    final List<BarChartGroupData> barGroups = List.generate(4, (weekIdx) {
      final endDay = now.subtract(Duration(days: (3 - weekIdx) * 7));
      final startDay = endDay.subtract(const Duration(days: 7));

      final weekTxs = transactions.where((t) {
        return t.date.isAfter(startDay) &&
            t.date.isBefore(endDay.add(const Duration(days: 1)));
      }).toList();

      double income = 0;
      double expense = 0;

      for (final tx in weekTxs) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }

      return BarChartGroupData(
        x: weekIdx,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppColors.income,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expense,
            color: AppColors.expense,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
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
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Wk ${val.toInt() + 1}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.35),
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // Rules-based smart projections card
  Widget _buildProjectionsCard(
    List<Transaction> transactions,
    String symbol,
    TextTheme textTheme,
    double monthlyIncome,
  ) {
    double totalIncome = monthlyIncome;
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final savings = totalIncome - totalExpense;
    final projectedSavings = savings > 0 ? savings * 1.15 : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.cyanGradient,
      ),
      child: GlassCard(
        borderRadius: 22,
        customColor: Colors.black.withOpacity(0.12),
        customBorder: Border.all(color: Colors.white.withOpacity(0.08)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.offline_bolt_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Projections',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Projected Savings: ${CurrencyFormatter.format(projectedSavings, symbol: symbol)}',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Based on a 15% increase in weekly efficiency!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic AI Insight row item builder
  Widget _buildInsightItem(
    AIInsight insight,
    BuildContext context,
    TextTheme textTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color priorityColor;
    switch (insight.priority) {
      case InsightPriority.high:
        priorityColor = AppColors.expense;
        break;
      case InsightPriority.medium:
        priorityColor = AppColors.goal;
        break;
      case InsightPriority.low:
      default:
        priorityColor = AppColors.income;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 18,
        customBorder: Border.all(
          color: priorityColor.withOpacity(0.2),
          width: 1.2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(insight.icon, color: priorityColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          insight.priority.name.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExpensesWidget(TextTheme textTheme) {
    return Column(
      children: [
        const Icon(Icons.analytics_outlined, size: 44, color: Colors.white30),
        const SizedBox(height: 14),
        Text(
          'No Analytics Data',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white30),
        ),
      ],
    );
  }

  // Simple Helper to Filter transactions by Time selector index
  List<Transaction> _getFilteredTransactions(List<Transaction> allTxs) {
    final now = DateTime.now();
    if (_selectedFilterIndex == 0) {
      // Last 7 days
      final weekAgo = now.subtract(const Duration(days: 7));
      return allTxs.where((t) => t.date.isAfter(weekAgo)).toList();
    } else if (_selectedFilterIndex == 1) {
      // Current Month
      return allTxs
          .where((t) => t.date.month == now.month && t.date.year == now.year)
          .toList();
    } else {
      // Current Year
      return allTxs.where((t) => t.date.year == now.year).toList();
    }
  }

  Map<String, double> _getCategoryTotals(List<Transaction> list) {
    final map = <String, double>{};
    for (final tx in list.where((t) => t.type == TransactionType.expense)) {
      map[tx.category] = (map[tx.category] ?? 0.0) + tx.amount;
    }
    return map;
  }
}

class EntranceAnimator extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const EntranceAnimator({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<EntranceAnimator> createState() => _EntranceAnimatorState();
}

class _EntranceAnimatorState extends State<EntranceAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
