import 'package:flutter/material.dart';
import 'package:pantry/widgets/app_bar_logo.dart';

class MealPlansScreen extends StatelessWidget {
  const MealPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Meal Plans'),
        actions: [],
      ),
      body: Center(child: Text('Meal Plans coming in Phase 3')),
    );
  }
}
