import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/ai_insight.dart';

class AIInsightEngine {
  AIInsightEngine._();

  /// Generates a list of smart, personalized financial recommendations
  /// by analyzing recent transactions and active budget caps.
  static List<AIInsight> generateInsights({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required String currencySymbol,
  }) {
    final insights = <AIInsight>[];

    if (transactions.isEmpty) {
      insights.add(
        AIInsight(
          title: 'New Account Sandbox',
          message:
              'Welcome to Trackly Pro! Log your first transaction to unlock deep AI spending insights and automated category advice.',
          category: 'System',
          icon: Icons.lightbulb_outline,
          priority: InsightPriority.low,
        ),
      );
      return insights;
    }

    final now = DateTime.now();

    // Filter transactions for the current month
    final currentMonthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    // 1. Calculate general balances
    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in currentMonthTransactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    // 2. Budget Overspending Check (Rule 1)
    for (final budget in budgets) {
      // Calculate total spent in this budget's category for current month
      final spent = currentMonthTransactions
          .where(
            (t) =>
                t.category == budget.category &&
                t.type == TransactionType.expense,
          )
          .fold(0.0, (sum, item) => sum + item.amount);

      final progress = budget.calculateProgress(spent);

      if (progress >= 1.0) {
        insights.add(
          AIInsight(
            title: '${budget.category} Budget Exhausted',
            message:
                'Alert: You have overspent your ${budget.category} budget of $currencySymbol${budget.limitAmount.toStringAsFixed(0)} by $currencySymbol${(spent - budget.limitAmount).toStringAsFixed(2)}! Consider freezing non-essential transactions.',
            category: budget.category,
            icon: Icons.warning_amber_rounded,
            priority: InsightPriority.high,
          ),
        );
      } else if (progress >= 0.8) {
        insights.add(
          AIInsight(
            title: '${budget.category} Budget Alert',
            message:
                'Warning: You spent ${(progress * 100).toStringAsFixed(0)}% of your $currencySymbol${budget.limitAmount.toStringAsFixed(0)} ${budget.category} budget. Only $currencySymbol${(budget.limitAmount - spent).toStringAsFixed(2)} remaining!',
            category: budget.category,
            icon: Icons.notification_important_rounded,
            priority: InsightPriority.medium,
          ),
        );
      }
    }

    // 3. Deficit / Surplus check (Rule 2)
    if (totalIncome > 0) {
      final savingsRate = (totalIncome - totalExpense) / totalIncome;

      if (totalExpense > totalIncome) {
        insights.add(
          AIInsight(
            title: 'Deficit Spending Detected',
            message:
                'Urgent: Your monthly expense ($currencySymbol${totalExpense.toStringAsFixed(0)}) exceeds your monthly income ($currencySymbol${totalIncome.toStringAsFixed(0)}). We recommend pausing shopping items.',
            category: 'Balance',
            icon: Icons.trending_down_rounded,
            priority: InsightPriority.high,
          ),
        );
      } else if (savingsRate >= 0.35) {
        insights.add(
          AIInsight(
            title: 'Elite Savings Velocity',
            message:
                'Incredible! Your monthly savings rate is ${(savingsRate * 100).toStringAsFixed(0)}%, placing you in the top tier of wealth builders. Consider moving $currencySymbol${(totalIncome - totalExpense).toStringAsFixed(0)} to Investments!',
            category: 'Milestone',
            icon: Icons.stars_rounded,
            priority: InsightPriority.low,
          ),
        );
      } else if (savingsRate >= 0.15) {
        insights.add(
          AIInsight(
            title: 'Healthy Savings Rate',
            message:
                'Great job! You saved ${(savingsRate * 100).toStringAsFixed(0)}% of your income this month. Keep it up to easily reach your goals!',
            category: 'Balance',
            icon: Icons.thumb_up_alt_outlined,
            priority: InsightPriority.low,
          ),
        );
      }
    }

    // 4. Highest Category Expense Check (Rule 3)
    final expenseMap = <String, double>{};
    for (final t in currentMonthTransactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      expenseMap[t.category] = (expenseMap[t.category] ?? 0.0) + t.amount;
    }

    if (expenseMap.isNotEmpty) {
      // Find highest category
      final sortedCategories = expenseMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final highestCategory = sortedCategories.first.key;
      final highestSpent = sortedCategories.first.value;

      if (highestCategory == 'Food' && highestSpent > 100) {
        insights.add(
          AIInsight(
            title: 'Reduce Food Expenditures',
            message:
                'Food and dining represent your largest expenditure ($currencySymbol${highestSpent.toStringAsFixed(0)}). Pro-Tip: Packing home lunches twice a week can cut costs up to 30%!',
            category: 'Food',
            icon: Icons.restaurant_rounded,
            priority: InsightPriority.medium,
          ),
        );
      } else if (highestCategory == 'Shopping' && highestSpent > 150) {
        insights.add(
          AIInsight(
            title: 'Pause Shopping Spike',
            message:
                'Shopping is your top spending bucket ($currencySymbol${highestSpent.toStringAsFixed(0)}). AI Rule: Pause 48 hours before checking out to eliminate impulse shopping buys.',
            category: 'Shopping',
            icon: Icons.shopping_bag_rounded,
            priority: InsightPriority.medium,
          ),
        );
      } else if (highestCategory == 'Travel' && highestSpent > 100) {
        insights.add(
          AIInsight(
            title: 'Commute Fee Optimization',
            message:
                'Transit represents a sizable expenditure ($currencySymbol${highestSpent.toStringAsFixed(0)}). Consider carpooling, transit cards, or auditing ride-share subscriptions.',
            category: 'Travel',
            icon: Icons.directions_car_rounded,
            priority: InsightPriority.medium,
          ),
        );
      } else if (highestCategory == 'Bills') {
        insights.add(
          AIInsight(
            title: 'Infrastructure Audit',
            message:
                'Substantial spending on recurring utilities/bills. Audit unused subscriptions or check if smart-thermostats/clean rates can reduce energy drafts.',
            category: 'Bills',
            icon: Icons.receipt_long_rounded,
            priority: InsightPriority.low,
          ),
        );
      }
    }

    // Ensure we always have at least 2 default insights to keep the UI beautiful
    if (insights.length < 2) {
      insights.add(
        AIInsight(
          title: 'Smart Wealth Allocation',
          message:
              'Rule of thumb: Allocate 50% to Needs, 30% to Wants, and 20% to Savings or Debt reduction to maintain premium compound security.',
          category: 'Wealth',
          icon: Icons.account_balance_wallet_outlined,
          priority: InsightPriority.low,
        ),
      );
    }

    return insights;
  }
}
