import 'package:flutter/material.dart';

const brand = Color(0xFF0F9D77);
const incomeColor = Color(0xFF16A34A);
const expenseColor = Color(0xFFE5484D);

const categoryColors = <String, Color>{
  'food': Color(0xFFF59E0B),
  'transport': Color(0xFF3B82F6),
  'housing': Color(0xFF8B5CF6),
  'utilities': Color(0xFF06B6D4),
  'health': Color(0xFFEC4899),
  'shopping': Color(0xFFF97316),
  'entertainment': Color(0xFF6366F1),
  'education': Color(0xFF14B8A6),
  'savings': Color(0xFF22C55E),
  'other': Color(0xFF94A3B8),
  'salary': Color(0xFF16A34A),
  'freelance': Color(0xFF0EA5E9),
  'gift': Color(0xFFEC4899),
  'other_income': Color(0xFF84CC16),
};

const categoryIcons = <String, IconData>{
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_bus_rounded,
  'housing': Icons.home_rounded,
  'utilities': Icons.bolt_rounded,
  'health': Icons.favorite_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'entertainment': Icons.movie_rounded,
  'education': Icons.school_rounded,
  'savings': Icons.savings_rounded,
  'other': Icons.category_rounded,
  'salary': Icons.payments_rounded,
  'freelance': Icons.laptop_mac_rounded,
  'gift': Icons.card_giftcard_rounded,
  'other_income': Icons.add_card_rounded,
};

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: b);
  final dark = b == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0E1412) : const Color(0xFFF5F8F7),
    fontFamilyFallback: const ['Noto Sans Ethiopic', 'Abyssinica SIL'],
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF16201D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: dark ? const Color(0xFF24332E) : const Color(0xFFE3EBE8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, scrolledUnderElevation: 0),
    navigationBarTheme: const NavigationBarThemeData(height: 68),
  );
}
