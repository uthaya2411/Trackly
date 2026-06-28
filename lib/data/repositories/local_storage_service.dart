import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class LocalStorageService {
  static const String _keyTransactions = 'trackly_transactions';
  static const String _keyBudgets = 'trackly_budgets';
  static const String _keyThemeMode = 'trackly_theme_mode';
  static const String _keyCurrency = 'trackly_currency';
  static const String _keyOnboarded = 'trackly_onboarded';
  static const String _keyGuestName = 'trackly_guest_name';
  static const String _keyGuestIncome = 'trackly_guest_income';
  static const String _keyGuestSavingsGoal = 'trackly_guest_goal';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Initialize service
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Transactions ---

  Future<void> saveTransactions(List<Transaction> list) async {
    final jsonList = list.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyTransactions, jsonEncode(jsonList));
  }

  List<Transaction> loadTransactions() {
    final dataString = _prefs.getString(_keyTransactions);
    if (dataString == null) {
      // Seed initial premium dummy data so graphs look spectacular right away
      final seeded = _getSeedTransactions();
      saveTransactions(seeded);
      return seeded;
    }

    try {
      final jsonList = jsonDecode(dataString) as List<dynamic>;
      return jsonList
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Budgets ---

  Future<void> saveBudgets(List<Budget> list) async {
    final jsonList = list.map((b) => b.toJson()).toList();
    await _prefs.setString(_keyBudgets, jsonEncode(jsonList));
  }

  List<Budget> loadBudgets() {
    final dataString = _prefs.getString(_keyBudgets);
    if (dataString == null) {
      // Seed default budgets per category
      final seeded = _getSeedBudgets();
      saveBudgets(seeded);
      return seeded;
    }

    try {
      final jsonList = jsonDecode(dataString) as List<dynamic>;
      return jsonList
          .map((item) => Budget.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Theme preference (Dark: true, Light: false) ---

  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(_keyThemeMode, isDark);
  }

  bool loadThemeMode() {
    return _prefs.getBool(_keyThemeMode) ??
        true; // Default to Dark mode (premium)
  }

  // --- Base Currency Symbol ---

  Future<void> saveCurrency(String symbol) async {
    await _prefs.setString(_keyCurrency, symbol);
  }

  String loadCurrency() {
    return _prefs.getString(_keyCurrency) ?? '₹'; // Default to Indian Rupee (₹)
  }

  // --- Onboarding Complete State ---

  Future<void> saveOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboarded, completed);
  }

  bool loadOnboardingCompleted() {
    return _prefs.getBool(_keyOnboarded) ?? false;
  }

  Future<void> saveGuestName(String name) async {
    await _prefs.setString(_keyGuestName, name);
  }

  String loadGuestName() {
    return _prefs.getString(_keyGuestName) ?? "";
  }

  Future<void> saveGuestIncome(double income) async {
    await _prefs.setString(_keyGuestIncome, income.toString());
  }

  double loadGuestIncome() {
    final incomeStr = _prefs.getString(_keyGuestIncome);
    return incomeStr != null ? (double.tryParse(incomeStr) ?? 0.0) : 0.0;
  }

  Future<void> saveGuestSavingsGoal(double goal) async {
    await _prefs.setString(_keyGuestSavingsGoal, goal.toString());
  }

  double loadGuestSavingsGoal() {
    final goalStr = _prefs.getString(_keyGuestSavingsGoal);
    return goalStr != null ? (double.tryParse(goalStr) ?? 0.0) : 0.0;
  }

  // --- Clean all data ---

  Future<void> clearAll() async {
    await _prefs.remove(_keyTransactions);
    await _prefs.remove(_keyBudgets);
    await _prefs.remove(_keyThemeMode);
    await _prefs.remove(_keyCurrency);
    await _prefs.remove(_keyOnboarded);
    await _prefs.remove(_keyGuestName);
    await _prefs.remove(_keyGuestIncome);
    await _prefs.remove(_keyGuestSavingsGoal);
  }

  // --- PRE-SEEDED PREMIUM FINANCIAL DATA ---

  List<Transaction> _getSeedTransactions() {
    final now = DateTime.now();

    return [
      Transaction(
        title: 'Monthly retainer payout',
        amount: 125000.00,
        category: 'Salary',
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 10)),
        note: 'Tech Consulting Retainer Invoice #40',
      ),
      Transaction(
        title: 'Mutual Fund Dividend',
        amount: 15000.00,
        category: 'Investment',
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 3)),
        note: 'Nifty 50 Index Fund quarterly distribution payout',
      ),
      Transaction(
        title: 'Reliance Fresh Grocery',
        amount: 4500.00,
        category: 'Food',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 7)),
        note: 'Weekly organic kitchen supply shopping',
      ),
      Transaction(
        title: 'Uber Premier Business Ride',
        amount: 1200.00,
        category: 'Travel',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 6)),
        note: 'Airport terminal transit commute',
      ),
      Transaction(
        title: 'AWS Cloud Servers',
        amount: 2500.00,
        category: 'Bills',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 5)),
        note: 'Infrastructure server instances hosting',
      ),
      Transaction(
        title: 'Premium Linen Kurta',
        amount: 3500.00,
        category: 'Shopping',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 4)),
        note: 'Festive season apparel curation',
      ),
      Transaction(
        title: 'Blue Tokai Espresso',
        amount: 450.00,
        category: 'Food',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 3)),
        note: 'Specialty coffee and light snacks',
      ),
      Transaction(
        title: 'Sovereign Gold Bond',
        amount: 15000.00,
        category: 'Investment',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 2)),
        note: 'Reserve assets purchase',
      ),
      Transaction(
        title: 'Zodiak Gourmet Diner',
        amount: 3200.00,
        category: 'Food',
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 1)),
        note: 'Appreciation team dinner gatherings',
      ),
      Transaction(
        title: 'Air India Flight Ticket',
        amount: 8500.00,
        category: 'Travel',
        type: TransactionType.expense,
        date: now,
        note: 'Regional business meeting travel booking',
      ),
    ];
  }

  List<Budget> _getSeedBudgets() {
    final now = DateTime.now();
    final currentMonthYear =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return [
      Budget(
        category: 'Food',
        limitAmount: 15000.00,
        monthYear: currentMonthYear,
      ),
      Budget(
        category: 'Travel',
        limitAmount: 20000.00,
        monthYear: currentMonthYear,
      ),
      Budget(
        category: 'Bills',
        limitAmount: 10000.00,
        monthYear: currentMonthYear,
      ),
      Budget(
        category: 'Shopping',
        limitAmount: 15000.00,
        monthYear: currentMonthYear,
      ),
      Budget(
        category: 'Investment',
        limitAmount: 35000.00,
        monthYear: currentMonthYear,
      ),
    ];
  }
}
