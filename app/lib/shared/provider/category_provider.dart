import 'package:flutter/material.dart';
import '../../../shared/models/category.dart';
import '../../features/category_editor/utils/category_editor_utils.dart';
import '../utils/categories_fetch.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<void> fetch() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await fetchCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create — awaits API, throws on failure, list unchanged if error ───────

  Future<void> add(Category category) async {
    await createCategory(
      id: category.id,
      name: category.name,
      color: category.color,
      isProductive: category.isProductive,
    );
    // Only reached if the above didn't throw (i.e. server returned 2xx)
    _categories = [..._categories, category];
    notifyListeners();
  }

  // ── Update ───────────────────────────────────────────────────────────────

  Future<void> update(Category updated) async {
    await editCategory(
      id: updated.id,
      name: updated.name,
      color: updated.color,
      isProductive: updated.isProductive,
    );
    _categories = [
      for (final c in _categories)
        if (c.id == updated.id) updated else c,
    ];
    notifyListeners();
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> delete(String categoryId) async {
    await deleteCategory(categoryId);
    _categories = _categories.where((c) => c.id != categoryId).toList();
    notifyListeners();
  }
}