import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recipe_url_service.dart';

final recipeUrlServiceProvider =
    Provider<RecipeUrlService>((_) => RecipeUrlService());
