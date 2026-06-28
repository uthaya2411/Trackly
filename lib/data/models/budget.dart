class Budget {
  final String category; // Food, Travel, Bills, Shopping, Salary, Investment
  final double limitAmount;
  final String monthYear; // Format: YYYY-MM (e.g. "2026-05")

  Budget({
    required this.category,
    required this.limitAmount,
    required this.monthYear,
  });

  // Create a copy of this object with optional new values
  Budget copyWith({String? category, double? limitAmount, String? monthYear}) {
    return Budget(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  // Convert a JSON Map into a Budget object (Deserialization)
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      category: json['category'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      monthYear: json['monthYear'] as String,
    );
  }

  // Convert a Budget object into a JSON Map (Serialization)
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'limitAmount': limitAmount,
      'monthYear': monthYear,
    };
  }

  // Visual helper to calculate consumption percentage (0.0 to 1.0+)
  double calculateProgress(double spentAmount) {
    if (limitAmount <= 0) return 0.0;
    return spentAmount / limitAmount;
  }
}
