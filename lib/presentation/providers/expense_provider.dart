import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/budget.dart';
import '../../data/repositories/local_storage_service.dart';
import '../../data/services/ai_insight_engine.dart';
import '../../data/models/ai_insight.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

// Immutable state structure that powers all our screens
class ExpenseState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final bool isDarkMode;
  final String currencySymbol;
  final bool isOnboarded;
  final bool isSyncing;
  final List<String> syncLogs;
  final List<String> connectedDevices;
  final bool isFirebaseConnected;
  final String activeUserEmail;
  final String guestName;
  final double monthlyIncome;
  final double savingsGoal;

  ExpenseState({
    required this.transactions,
    required this.budgets,
    required this.isDarkMode,
    required this.currencySymbol,
    required this.isOnboarded,
    this.isSyncing = false,
    this.syncLogs = const [],
    this.connectedDevices = const [
      'iPhone 15 Pro (Active)',
      'Chrome Web Client',
      'Antigravity Workspace',
    ],
    this.isFirebaseConnected = false,
    this.activeUserEmail = '',
    this.guestName = '',
    this.monthlyIncome = 0.0,
    this.savingsGoal = 0.0,
  });

  ExpenseState copyWith({
    List<Transaction>? transactions,
    List<Budget>? budgets,
    bool? isDarkMode,
    String? currencySymbol,
    bool? isOnboarded,
    bool? isSyncing,
    List<String>? syncLogs,
    List<String>? connectedDevices,
    bool? isFirebaseConnected,
    String? activeUserEmail,
    String? guestName,
    double? monthlyIncome,
    double? savingsGoal,
  }) {
    return ExpenseState(
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isSyncing: isSyncing ?? this.isSyncing,
      syncLogs: syncLogs ?? this.syncLogs,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isFirebaseConnected: isFirebaseConnected ?? this.isFirebaseConnected,
      activeUserEmail: activeUserEmail ?? this.activeUserEmail,
      guestName: guestName ?? this.guestName,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
    );
  }
}

// Provider for LocalStorageService so Riverpod can supply it cleanly
final localStorageProvider = Provider<LocalStorageService>((ref) {
  // Overridden in main.dart upon startup
  throw UnimplementedError();
});

// The global ExpenseProvider powered by Riverpod Notifier
final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(() {
  return ExpenseNotifier();
});

class ExpenseNotifier extends Notifier<ExpenseState> {
  late LocalStorageService _storage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  ExpenseState build() {
    // Read the injected storage service from our other provider
    _storage = ref.watch(localStorageProvider);

    // Load initial values from cache
    final transactions = _storage.loadTransactions();
    final budgets = _storage.loadBudgets();
    final isDarkMode = _storage.loadThemeMode();
    final currencySymbol = _storage.loadCurrency();
    final isOnboarded = _storage.loadOnboardingCompleted();
    final guestName = _storage.loadGuestName();
    final monthlyIncome = _storage.loadGuestIncome();
    final savingsGoal = _storage.loadGuestSavingsGoal();

    final currentUser = FirebaseAuth.instance.currentUser;
    final isFirebaseConnected = currentUser != null;
    final activeUserEmail = isFirebaseConnected
        ? (currentUser.email ?? '')
        : guestName;

    return ExpenseState(
      transactions: transactions,
      budgets: budgets,
      isDarkMode: isDarkMode,
      currencySymbol: currencySymbol,
      isOnboarded: isOnboarded,
      guestName: guestName,
      monthlyIncome: monthlyIncome,
      savingsGoal: savingsGoal,
      activeUserEmail: activeUserEmail,
      isFirebaseConnected: isFirebaseConnected,
    );
  }

  // --- Actions ---
  //To save custom guest Profile
  void saveGuestProfile({
    required String name,
    required double income,
    required double goal,
  }) {
    //1. save to phone disk storage
    _storage.saveGuestName(name);
    _storage.saveGuestIncome(income);
    _storage.saveGuestSavingsGoal(goal);

    //2. update riverpod in memory state
    state = state.copyWith(
      guestName: name,
      monthlyIncome: income,
      activeUserEmail: name,
      savingsGoal: goal,
    );
    // Sync profile settings to Firestore if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state.isFirebaseConnected && currentUser != null) {
      _firestore.collection('users').doc(currentUser.email ?? '').set({
        'guestName': name,
        'monthlyIncome': income,
        'savingsGoal': goal,
        'currencySymbol': state.currencySymbol,
        'email': currentUser.email ?? '',
      }, SetOptions(merge: true));
    }
  }

  /// Adds a transaction and automatically caches it
  void addTransaction(Transaction tx) {
    final updatedList = [tx, ...state.transactions];
    state = state.copyWith(transactions: updatedList);
    _storage.saveTransactions(updatedList);
    // Sync to Firestore in real-time if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state.isFirebaseConnected && currentUser != null) {
      _uploadTransaction(currentUser.email ?? '', tx);
    }
  }

  /// Deletes a transaction by ID
  void deleteTransaction(String id) {
    // Find transaction in state BEFORE removing it
    final txList = state.transactions;
    final int index = txList.indexWhere((t) => t.id == id);
    Transaction? txToDelete;
    if (index != -1) {
      txToDelete = txList[index];
    }

    final updatedList = txList.where((t) => t.id != id).toList();
    state = state.copyWith(transactions: updatedList);
    _storage.saveTransactions(updatedList);
    // Sync deletion to Firestore if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state.isFirebaseConnected && currentUser != null) {
      _deleteTransactionFromFirestore(currentUser.email ?? '', id, txToDelete);
    }
  }

  /// Sets or updates a budget cap for a category
  void setBudget(String category, double amount) {
    final now = DateTime.now();
    final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final list = List<Budget>.from(state.budgets);
    final idx = list.indexWhere(
      (b) => b.category == category && b.monthYear == monthYear,
    );

    Budget updatedBudget;
    if (idx != -1) {
      list[idx] = list[idx].copyWith(limitAmount: amount);
      updatedBudget = list[idx];
    } else {
      updatedBudget = Budget(
        category: category,
        limitAmount: amount,
        monthYear: monthYear,
      );
      list.add(updatedBudget);
    }

    state = state.copyWith(budgets: list);
    _storage.saveBudgets(list);

    // Sync to Firestore in real-time if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state.isFirebaseConnected && currentUser != null) {
      _uploadBudget(currentUser.email ?? '', updatedBudget);
    }
  }

  /// Toggles theme styling and saves the selection
  void toggleTheme() {
    final nextMode = !state.isDarkMode;
    state = state.copyWith(isDarkMode: nextMode);
    _storage.saveThemeMode(nextMode);
  }

  /// Updates primary currency symbol globally
  void setCurrency(String symbol) {
    state = state.copyWith(currencySymbol: symbol);
    _storage.saveCurrency(symbol);

    // Sync currency to Firestore if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state.isFirebaseConnected && currentUser != null) {
      _firestore.collection('users').doc(currentUser.email ?? '').set({
        'currencySymbol': symbol,
      }, SetOptions(merge: true));
    }
  }

  /// Saves onboarding finished state
  void completeOnboarding() {
    state = state.copyWith(isOnboarded: true);
    _storage.saveOnboardingCompleted(true);
  }

  /// Performs full system wipe for security/demo resetting
  Future<void> resetAll() async {
    await _storage.clearAll();

    // Force re-read to seed defaults
    final seededTx = _storage.loadTransactions();
    final seededBudgets = _storage.loadBudgets();

    state = ExpenseState(
      transactions: seededTx,
      budgets: seededBudgets,
      isDarkMode: true,
      currencySymbol: '₹',
      isOnboarded: false,
      isFirebaseConnected: false,
      activeUserEmail: '',
    );
  }

  // --- Interactive AI Insights Computed Value ---

  List<AIInsight> get aiInsights {
    return AIInsightEngine.generateInsights(
      transactions: state.transactions,
      budgets: state.budgets,
      currencySymbol: state.currencySymbol,
    );
  }

  // --- Visual cloud sync engine simulation ---

  Future<void> runCloudSyncSimulation() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, syncLogs: []);

    final logs = [
      '⚡ Initializing secure handshake connection...',
      '🔍 Scanning offline SQLite cached database ledger...',
      '📂 Identified ${state.transactions.length} local operations, scanning indices...',
      '🌐 Handshake accepted by central node [AWS-West-2]',
      '🔑 Authenticating secure RSA-4096 tokens...',
      '🔄 Comparing database delta schemas...',
      '📤 Syncing payload data packets to remote Firestore...',
      '📊 Recalculating charts, analytics, and budget ceilings...',
      '✅ Cloud Sync completed successfully! Node status: ONLINE.',
    ];

    for (var i = 0; i < logs.length; i++) {
      await Future.delayed(Duration(milliseconds: 300 + (i % 2 * 200)));
      state = state.copyWith(syncLogs: [...state.syncLogs, logs[i]]);
    }

    state = state.copyWith(
      isSyncing: false,
      isFirebaseConnected: true,
      activeUserEmail: state.activeUserEmail.isEmpty
          ? 'guest.portfolio@trackly.pro'
          : state.activeUserEmail,
    );
  }

  // --- Guest Mode Entry Points ---

  /// Wipes all database tables to start completely fresh under Indian Rupees
  Future<void> startGuestFresh() async {
    state = state.copyWith(isSyncing: true);
    await Future.delayed(const Duration(milliseconds: 800));
    await _storage.clearAll();

    // Explicitly cache empty lists so automated initial seeding is bypassed
    await _storage.saveTransactions([]);
    await _storage.saveBudgets([]);
    await _storage.saveCurrency('₹');
    await _storage.saveOnboardingCompleted(true);

    state = ExpenseState(
      transactions: [],
      budgets: [],
      isDarkMode: true,
      currencySymbol: '₹',
      isOnboarded: true,
      isFirebaseConnected: false,
      activeUserEmail: 'Guest User (Fresh)',
    );
  }

  /// Sets up guest demo mode using the Indian Rupee seeds
  Future<void> startGuestDemo() async {
    state = state.copyWith(isSyncing: true);
    await Future.delayed(const Duration(milliseconds: 800));
    await _storage.clearAll();

    // Trigger seeding by clearing the SharedPreferences key
    final seededTx = _storage.loadTransactions();
    final seededBudgets = _storage.loadBudgets();
    await _storage.saveCurrency('₹');
    await _storage.saveGuestName("Guest User (Demo)");

    await _storage.saveOnboardingCompleted(true);

    state = ExpenseState(
      transactions: seededTx,
      budgets: seededBudgets,
      isDarkMode: true,
      currencySymbol: '₹',
      isOnboarded: true,
      isFirebaseConnected: false,
      activeUserEmail: 'Guest User (Demo)',
    );
  }

  // --- Mock Authentication (Google Sign-In or Email) ---

  Future<bool> signInMock(
    String email,
    String password, {
    bool isNewUser = false,
  }) async {
    state = state.copyWith(isSyncing: true);
    await Future.delayed(
      const Duration(milliseconds: 1200),
    ); // Smooth loader delay

    if (isNewUser) {
      // Clear persistent storage to represent a brand new Firebase user profile (completely empty)
      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);

      state = ExpenseState(
        transactions: [],
        budgets: [],
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: true,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );
    } else {
      // Existing user: seed or keep active transactions representing populated sync state
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);

      final currentTx = _storage.loadTransactions();
      final currentBudgets = _storage.loadBudgets();

      state = ExpenseState(
        transactions: currentTx,
        budgets: currentBudgets,
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: true,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );
    }
    return true;
  }

  Future<void> signOutMock() async {
    state = state.copyWith(isSyncing: true);
    await Future.delayed(const Duration(milliseconds: 800));

    state = ExpenseState(
      transactions: [],
      budgets: [],
      isDarkMode: true,
      currencySymbol: '₹',
      isOnboarded: false,
      isFirebaseConnected: false,
      activeUserEmail: '',
    );
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isSyncing: true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Clear local storage database context so the new account starts fresh
      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);
      state = ExpenseState(
        transactions: [],
        budgets: [],
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: true,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isSyncing: true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);

      final currentTx = _storage.loadTransactions();
      final currentBudgets = _storage.loadBudgets();
      state = ExpenseState(
        transactions: currentTx,
        budgets: currentBudgets,
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: true,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isSyncing: true);
    try {
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);
      state = ExpenseState(
        transactions: [],
        budgets: [],
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: false,
        isFirebaseConnected: false,
        activeUserEmail: '',
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isSyncing: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Wipe Firestore cloud data first while still authenticated
        await clearFirestoreBackup(user.email ?? '');

        // 2. Delete user account in Firebase Auth
        await user.delete();
      }
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(false);

      state = ExpenseState(
        transactions: [],
        budgets: [],
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: false,
        isFirebaseConnected: false,
        activeUserEmail: '',
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isSyncing: true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final email = userCredential.user?.email ?? 'google.user@trackly.pro';

      await _storage.clearAll();
      await _storage.saveTransactions([]);
      await _storage.saveBudgets([]);
      await _storage.saveCurrency('₹');
      await _storage.saveOnboardingCompleted(true);

      final currentTx = _storage.loadTransactions();
      final currentBudgets = _storage.loadBudgets();

      state = ExpenseState(
        transactions: currentTx,
        budgets: currentBudgets,
        isDarkMode: true,
        currencySymbol: '₹',
        isOnboarded: true,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<bool> hasFireStoreBackup(String email) async {
    try {
      // 1. Check if the user document itself exists (contains profile settings)
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        return true;
      }

      // 2. Check if they have any transactions
      final snapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking Firestore backup: $e');
      return false;
    }
  }

  /// Upload a single transaction to Firestore
  Future<void> _uploadTransaction(String email, Transaction tx) async {
    try {
      final timeStamp = '${tx.date.hour.toString().padLeft(2, '0')}${tx.date.minute.toString().padLeft(2, '0')}${tx.date.second.toString().padLeft(2, '0')}';
      final docId = '${tx.date.toIso8601String().split('T').first}_${tx.type.name.toUpperCase()}_${tx.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timeStamp';
      await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .doc(docId)
          .set(tx.toJson());
    } catch (e) {
      print('Error uploading transaction: $e');
    }
  }

  /// Delete a single transaction from Firestore
  Future<void> _deleteTransactionFromFirestore(String email, String id, [Transaction? tx]) async {
    try {
      if (tx != null) {
        final timeStamp = '${tx.date.hour.toString().padLeft(2, '0')}${tx.date.minute.toString().padLeft(2, '0')}${tx.date.second.toString().padLeft(2, '0')}';
        final docId = '${tx.date.toIso8601String().split('T').first}_${tx.type.name.toUpperCase()}_${tx.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timeStamp';
        await _firestore
            .collection('users')
            .doc(email)
            .collection('transactions')
            .doc(docId)
            .delete();

        // Also try deleting by old UUID-suffixed format for backward compatibility
        final oldDocId = '${tx.date.toIso8601String().split('T').first}_${tx.type.name.toUpperCase()}_${tx.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${tx.id}';
        await _firestore
            .collection('users')
            .doc(email)
            .collection('transactions')
            .doc(oldDocId)
            .delete();
      }
      // Fallback/backward compatibility: also try deleting by raw ID
      await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting transaction from Firestore: $e');
    }
  }

  /// Upload a single budget to Firestore
  Future<void> _uploadBudget(String email, Budget budget) async {
    try {
      final budgetDocId = '${budget.category}_${budget.monthYear}';
      await _firestore
          .collection('users')
          .doc(email)
          .collection('budgets')
          .doc(budgetDocId)
          .set(budget.toJson());
    } catch (e) {
      print('Error uploading budget: $e');
    }
  }

  /// Upload all current transactions and budgets in one batch to Firestore
  Future<void> syncAllDataToFirestore(String email) async {
    try {
      final batch = _firestore.batch();

      final userDocRef = _firestore.collection('users').doc(email);
      final currentUser = FirebaseAuth.instance.currentUser;
      batch.set(userDocRef, {
        'guestName': state.guestName,
        'monthlyIncome': state.monthlyIncome,
        'savingsGoal': state.savingsGoal,
        'currencySymbol': state.currencySymbol,
        'email': currentUser?.email ?? '',
      }, SetOptions(merge: true));

      // Add all transactions to batch
      for (final tx in state.transactions) {
        final timeStamp = '${tx.date.hour.toString().padLeft(2, '0')}${tx.date.minute.toString().padLeft(2, '0')}${tx.date.second.toString().padLeft(2, '0')}';
        final docId = '${tx.date.toIso8601String().split('T').first}_${tx.type.name.toUpperCase()}_${tx.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timeStamp';
        final docRef = _firestore
            .collection('users')
            .doc(email)
            .collection('transactions')
            .doc(docId);
        batch.set(docRef, tx.toJson());
      }
      // Add all budgets to batch
      for (final budget in state.budgets) {
        final docId = '${budget.category}_${budget.monthYear}';
        final docRef = _firestore
            .collection('users')
            .doc(email)
            .collection('budgets')
            .doc(docId);
        batch.set(docRef, budget.toJson());
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing all data to Firestore: $e');
      rethrow;
    }
  }

  Future<void> restoreBackupFromFirestore(String email) async {
    state = state.copyWith(isSyncing: true);
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      String guestName = state.guestName;
      double monthlyIncome = state.monthlyIncome;
      double savingsGoal = state.savingsGoal;
      String currencySymbol = state.currencySymbol;
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          guestName = data['guestName'] as String? ?? guestName;
          monthlyIncome =
              (data['monthlyIncome'] as num?)?.toDouble() ?? monthlyIncome;
          savingsGoal =
              (data['savingsGoal'] as num?)?.toDouble() ?? savingsGoal;

          currencySymbol = data['currencySymbol'] as String? ?? currencySymbol;
        }
      }
      // 2. Fetch transactions from Firestore
      final txSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .get();
      final List<Transaction> txs = txSnapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();

      // 3. Fetch budgets from Firestore
      final budgetSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('budgets')
          .get();

      final List<Budget> budgets = budgetSnapshot.docs
          .map((doc) => Budget.fromJson(doc.data()))
          .toList();
      // 4. Save to local storage
      await _storage.saveGuestName(guestName);
      await _storage.saveGuestIncome(monthlyIncome);
      await _storage.saveGuestSavingsGoal(savingsGoal);
      await _storage.saveCurrency(currencySymbol);
      await _storage.saveTransactions(txs);
      await _storage.saveBudgets(budgets);
      // 5. Update Riverpod memory state
      state = state.copyWith(
        guestName: guestName,
        monthlyIncome: monthlyIncome,
        savingsGoal: savingsGoal,
        currencySymbol: currencySymbol,
        transactions: txs,
        budgets: budgets,
        isFirebaseConnected: true,
        activeUserEmail: FirebaseAuth.instance.currentUser?.email ?? '',
      );
    } catch (e) {
      print('Error restoring backup: $e');
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Clear all user data from Firestore
  Future<void> clearFirestoreBackup(String email) async {
    try {
      final txSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .get();
      final budgetSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('budgets')
          .get();
      final batch = _firestore.batch();
      for (final doc in txSnapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in budgetSnapshot.docs) {
        batch.delete(doc.reference);
      }
      // Delete the parent user profile document itself
      final userDocRef = _firestore.collection('users').doc(email);
      batch.delete(userDocRef);

      await batch.commit();
    } catch (e) {
      print('Error clearing Firestore backup: $e');
      rethrow;
    }
  }

  /// Merge local sandbox data with Firestore backups
  Future<void> mergeLocalDataWithFirestore(String email) async {
    state = state.copyWith(isSyncing: true);
    try {
      // 1. Fetch transactions from Firestore
      final txSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('transactions')
          .get();
      final List<Transaction> cloudTxs = txSnapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();

      // Combine with local transactions (no duplicates by transaction ID)
      final Map<String, Transaction> mergedTxsMap = {};
      for (final tx in cloudTxs) {
        mergedTxsMap[tx.id] = tx;
      }
      for (final tx in state.transactions) {
        mergedTxsMap[tx.id] = tx;
      }
      final List<Transaction> mergedTxs = mergedTxsMap.values.toList();

      // 2. Fetch budgets from Firestore
      final budgetSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('budgets')
          .get();
      final List<Budget> cloudBudgets = budgetSnapshot.docs
          .map((doc) => Budget.fromJson(doc.data()))
          .toList();

      // Combine with local budgets
      final Map<String, Budget> mergedBudgetsMap = {};
      for (final b in cloudBudgets) {
        final key = '${b.category}_${b.monthYear}';
        mergedBudgetsMap[key] = b;
      }
      for (final b in state.budgets) {
        final key = '${b.category}_${b.monthYear}';
        mergedBudgetsMap[key] = b;
      }
      final List<Budget> mergedBudgets = mergedBudgetsMap.values.toList();

      // 3. Save to local storage
      await _storage.saveTransactions(mergedTxs);
      await _storage.saveBudgets(mergedBudgets);

      // 4. Update Riverpod state
      state = state.copyWith(
        transactions: mergedTxs,
        budgets: mergedBudgets,
        isFirebaseConnected: true,
        activeUserEmail: email,
      );

      // 5. Upload everything back to Firestore to ensure it is in sync
      await syncAllDataToFirestore(email);
    } catch (e) {
      print('Error merging data: $e');
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}
