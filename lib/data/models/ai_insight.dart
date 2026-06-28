import 'package:flutter/material.dart';

enum InsightPriority { high, medium, low }

class AIInsight {
  final String title;
  final String message;
  final String category;
  final IconData icon;
  final InsightPriority priority;

  AIInsight({
    required this.title,
    required this.message,
    required this.category,
    required this.icon,
    required this.priority,
  });
}
