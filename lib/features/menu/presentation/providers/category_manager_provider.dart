import 'package:flutter/foundation.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_sub_categories.dart';

class CategoryManagerProvider extends ChangeNotifier {
  final GetMainCategories getMainCategoriesUseCase;
  final GetSubCategories getSubCategoriesUseCase;

  CategoryManagerProvider({required this.getMainCategoriesUseCase, required this.getSubCategoriesUseCase});

  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> tree = [];

  // Getters for UI to consume
  List<Map<String, dynamic>> get displayTree => isLoading ? _loadingTree : tree;

  // Initial Load
  Future<void> loadTree() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final mainsResult = await getMainCategoriesUseCase(NoParams());

      await mainsResult.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
        },
        (mains) async {
          List<Map<String, dynamic>> builtTree = [];

          for (var main in mains) {
            final subsResult = await getSubCategoriesUseCase(GetSubCategoriesParams(main.id));
            List<Map<String, dynamic>> subsList = [];

            subsResult.fold(
              (failure) => null, // Ignore sub-cat failure or log it
              (subs) {
                subsList = subs.map((s) => {'id': s.id, 'name': s.name}).toList();
              },
            );

            builtTree.add({
              'data': {'id': main.id, 'name': main.name},
              'subs': subsList,
            });
          }

          tree = builtTree;
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // Dummy Loading Data
  List<Map<String, dynamic>> get _loadingTree {
    return List.generate(
      6,
      (index) => {
        'data': {'id': 'dummy_$index', 'name': 'Loading Category Name...'},
        'subs': <Map<String, dynamic>>[],
      },
    );
  }
}
