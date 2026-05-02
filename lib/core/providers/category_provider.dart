import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryNotifier extends StateNotifier<String?> {
  CategoryNotifier() : super(null); // null means all categories

  void setCategory(String? category) {
    if (state == category) {
      state = null; // Toggle off if same category is clicked
    } else {
      state = category;
    }
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, String?>((ref) {
  return CategoryNotifier();
});
