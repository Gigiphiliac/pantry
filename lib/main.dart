import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';

import 'app.dart';

/// The active flavour, injected at build time via --dart-define=FLAVOR=dev|prod.
/// Defaults to 'dev' so `flutter run` (without --flavor) resolves to dev.
const String appFlavour = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

/// True when running the dev flavour.
bool get isDev => appFlavour == 'dev';

/// True when running the prod flavour.
bool get isProd => appFlavour == 'prod';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

void main() {
  // Flutter already downgrades platform channels in profile/release builds,
  // but assert early so we catch a flavour mismatch on a debug build.
  assert(() {
    debugPrint('🍦 Pantry — flavour: $appFlavour');
    return true;
  }());

  runApp(const ProviderScope(child: PantryApp()));
}
