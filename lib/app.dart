import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/shopping/shopping_lists_screen.dart';
import 'features/recipes/recipes_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/meal_plans/meal_plans_screen.dart';
import 'features/settings/settings_screen.dart';

class PantryApp extends ConsumerWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pantry',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
      ),
      home: const _NavShell(),
    );
  }
}

class _NavShell extends StatefulWidget {
  const _NavShell();

  @override
  State<_NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<_NavShell> {
  int _index = 0;

  static const _screens = [
    ShoppingListsScreen(),
    RecipesScreen(),
    PantryScreen(),
    MealPlansScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Lists',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Meal Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
