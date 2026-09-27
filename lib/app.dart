import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/shopping/shopping_lists_screen.dart';
import 'features/recipes/recipes_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/meal_plans/meal_plans_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/recipes/ocr/ocr_providers.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class PantryApp extends ConsumerWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).valueOrNull;
    final mode = switch (themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system || null => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Pantry',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const _NavShell(),
    );
  }
}

class _NavShell extends ConsumerStatefulWidget {
  const _NavShell();

  @override
  ConsumerState<_NavShell> createState() => _NavShellState();
}

class _NavShellState extends ConsumerState<_NavShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Initialise the OCR line classifier (loads LightGBM model from assets).
    // This is non-blocking — the classifier falls back to the heuristic stub
    // if the model asset isn't ready yet.
    ref.read(onnxClassifierProvider).init();
  }

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
