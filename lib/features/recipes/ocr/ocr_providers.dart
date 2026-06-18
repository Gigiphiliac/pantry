import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recipe_ocr_service.dart';

final recipeOcrServiceProvider =
    Provider<RecipeOcrService>((_) => RecipeOcrService());
