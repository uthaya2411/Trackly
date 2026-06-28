import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import 'glass_card.dart';

class PremiumVisaCard extends StatefulWidget {
  final double netBalance;
  final double totalIncome;
  final double totalExpense;
  final double monthlyIncome;
  final String symbol;
  final String email;
  final TextTheme textTheme;

  const PremiumVisaCard({
    super.key,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthlyIncome,
    required this.symbol,
    required this.email,
    required this.textTheme,
  });

  @override
  State<PremiumVisaCard> createState() => _PremiumVisaCardState();
}

class _PremiumVisaCardState extends State<PremiumVisaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment(
            -1.0 + _shimmerAnimation.value,
            -1.0 - _shimmerAnimation.value,
          ),
          end: Alignment(
            1.0 - _shimmerAnimation.value,
            1.0 + _shimmerAnimation.value,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        customColor: Colors.black.withOpacity(0.2), // Dark glaze overlay
        customBorder: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.5,
        ),
        child: child,
      ),
    );
  }

  Widget _buildFrontContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Brand & Chip Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TRACKLY PLATINUM',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 10,
              ),
            ),
            Container(
              width: 38,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          "TOTAL INCOME",
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(widget.monthlyIncome, symbol: widget.symbol),
          style: widget.textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Giant Net Balance Output
        Text(
          'NET CASH FLOW',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(widget.netBalance, symbol: widget.symbol),
          style: widget.textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),

        // Inflow vs Outflow grid
        Row(
          children: [
            // Inflow Block
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppColors.income,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INFLOW',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(
                              widget.totalIncome,
                              symbol: widget.symbol,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider line
            Container(
              width: 1.5,
              height: 32,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(width: 16),

            // Outflow Block
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.expense,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OUTFLOW',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(
                              widget.totalExpense,
                              symbol: widget.symbol,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return _buildCardContainer(child: _buildFrontContent());
      },
    );
  }
}
