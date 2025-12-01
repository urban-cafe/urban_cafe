import 'package:flutter/foundation.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/domain/usecases/get_categories.dart';
import 'package:urban_cafe/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/domain/usecases/get_sub_categories.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';

class MenuProvider extends ChangeNotifier {
  final _getMenuItems = GetMenuItems(MenuRepositoryImpl());
  final _getCategories = GetCategories(MenuRepositoryImpl());
  final _getMainCategories = GetMainCategories(MenuRepositoryImpl());
  final _getSubCategories = GetSubCategories(MenuRepositoryImpl());
  List<MenuItemEntity> items = [];
  List<String> categories = [];
  List<String> mainCategories = [];
  List<String> subCategories = [];
  bool loading = false;
  bool loadingMore = false;
  String? error;
  String? category;
  List<String>? categoryList;
  String? search;
  int _page = 1;
  final int _pageSize = 20;
  bool hasMore = true;

  Future<void> fetch({int page = 1}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _getMenuItems(page: page, pageSize: _pageSize, search: search, category: category, categories: categoryList);
      if (page <= 1) {
        items = result;
      } else {
        items = [...items, ...result];
      }
      hasMore = result.length == _pageSize;
      _page = page;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      categories = await _getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchMainCategories() async {
    try {
      mainCategories = await _getMainCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchSubCategories(String parentName) async {
    try {
      subCategories = await _getSubCategories(parentName);
      notifyListeners();
    } catch (_) {}
  }

  void setCategory(String? value) {
    category = value;
    categoryList = null;
    _page = 1;
    hasMore = true;
    fetch(page: 1);
  }

  void setCategories(List<String>? values) {
    categoryList = values;
    category = null;
    _page = 1;
    hasMore = true;
    fetch(page: 1);
  }

  void setSearch(String? value) {
    search = value;
    _page = 1;
    hasMore = true;
    fetch(page: 1);
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await _getMenuItems(page: nextPage, pageSize: _pageSize, search: search, category: category, categories: categoryList);
      items = [...items, ...result];
      hasMore = result.length == _pageSize;
      _page = nextPage;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }
}
