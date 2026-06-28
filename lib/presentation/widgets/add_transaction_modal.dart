import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../data/models/transaction.dart';
import '../providers/expense_provider.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() =>
      _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  // Categories configurations (Label -> Icon & Colors)
  final Map<String, _CategoryConfig> _categories = {
    'Food': _CategoryConfig(
      Icons.restaurant_rounded,
      AppColors.categoryFood,
      AppColors.roseGradient,
    ),
    'Travel': _CategoryConfig(
      Icons.directions_car_rounded,
      AppColors.categoryTravel,
      AppColors.cyanGradient,
    ),
    'Bills': _CategoryConfig(
      Icons.receipt_long_rounded,
      AppColors.categoryBills,
      AppColors.premiumGradient,
    ),
    'Shopping': _CategoryConfig(
      Icons.shopping_bag_rounded,
      AppColors.categoryShopping,
      AppColors.cyanGradient,
    ), // Cyan is beautiful for shopping too!
    'Salary': _CategoryConfig(
      Icons.monetization_on_rounded,
      AppColors.categorySalary,
      AppColors.emeraldGradient,
    ),
    'Investment': _CategoryConfig(
      Icons.trending_up_rounded,
      AppColors.categoryInvestment,
      AppColors.premiumGradient,
    ),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    // Create the transaction model
    final tx = Transaction(
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      type: _selectedType,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );

    // Write to our Riverpod state notifier
    ref.read(expenseProvider.notifier).addTransaction(tx);

    // Dynamic Haptic-like success indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('"${tx.title}" recorded successfully!'),
          ],
        ),
        backgroundColor: _selectedType == TransactionType.income
            ? AppColors.income
            : AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateData = ref.watch(expenseProvider);
    final textTheme = Theme.of(context).textTheme;

    final defaultBgColor = isDark
        ? AppColors.darkCard.withOpacity(
            0.85,
          ) // Frosted but solid enough to block background clutter
        : AppColors.lightCard.withOpacity(0.95);

    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: defaultBgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: defaultBorderColor, width: 1.5),
                left: BorderSide(color: defaultBorderColor, width: 1.0),
                right: BorderSide(color: defaultBorderColor, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Grab Bar
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.close_rounded,
                          size: 40,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                    Text(
                      'Record Transaction',
                      style: textTheme.titleLarge?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Date & Notes Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            label: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: textTheme.labelLarge?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Animated Income vs Expense Slider
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedType = TransactionType.expense,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedType == TransactionType.expense
                                      ? AppColors.expense.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.expense
                                        ? AppColors.expense.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Expense',
                                    style: textTheme.labelLarge?.copyWith(
                                      color:
                                          _selectedType ==
                                              TransactionType.expense
                                          ? AppColors.expense
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedType = TransactionType.income;
                                // Auto change default category to salary for income
                                if (_selectedCategory == 'Food' ||
                                    _selectedCategory == 'Travel' ||
                                    _selectedCategory == 'Shopping' ||
                                    _selectedCategory == 'Bills') {
                                  _selectedCategory = 'Salary';
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedType == TransactionType.income
                                      ? AppColors.income.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.income
                                        ? AppColors.income.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Income',
                                    style: textTheme.labelLarge?.copyWith(
                                      color:
                                          _selectedType ==
                                              TransactionType.income
                                          ? AppColors.income
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Text Field (Large Premium Numbers)
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{1,8}(\.\d{0,2})?$'),
                        ),
                      ],
                      style: textTheme.displayLarge?.copyWith(
                        color: _selectedType == TransactionType.income
                            ? AppColors.income
                            : AppColors.expense,
                        fontSize: 40,
                      ),
                      textAlign: TextAlign.center,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Please enter an amount';
                        if (double.tryParse(val) == null)
                          return 'Enter a valid decimal';
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixText: stateData.currencySymbol,
                        prefixStyle: textTheme.displayLarge?.copyWith(
                          color: _selectedType == TransactionType.income
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 40,
                        ),
                        hintText: '0.00',
                        hintStyle: textTheme.displayLarge?.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          fontSize: 40,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title Input
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: textTheme.bodyLarge,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Enter a description title';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Transaction Title',
                        hintText: 'e.g. Elegant Dinner, Uber, Retainer Pay',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Title Heading
                    Text(
                      'Select Category',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Category Selector Cards
                    SizedBox(
                      height: 96,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, idx) {
                          final catName = _categories.keys.elementAt(idx);
                          final catConfig = _categories[catName]!;
                          final isSelected = _selectedCategory == catName;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = catName),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 12),
                              width: 84,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? catConfig.gradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                          ? AppColors.darkCard
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: catConfig.color.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 12,
                                          spreadRadius: -2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    catConfig.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    catName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white60
                                                : Colors.black54),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notes input field
                    TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'Enter specific transaction details here...',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _selectedType == TransactionType.income
                              ? AppColors.emeraldGradient
                              : AppColors.roseGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_selectedType == TransactionType.income
                                          ? AppColors.income
                                          : AppColors.expense)
                                      .withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Confirm Record',
                            style: textTheme.labelLarge?.copyWith(
                              fontSize: 16,
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
          ),
        ),
      ),
    );
  }
}

// Config details helper for horizontal categories
class _CategoryConfig {
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  _CategoryConfig(this.icon, this.color, this.gradient);
}
