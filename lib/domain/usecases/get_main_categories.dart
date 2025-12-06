import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetMainCategories {
  final MenuRepository repository;
  const GetMainCategories(this.repository);

  // Now returns objects with IDs, not just strings
  Future<List<Map<String, dynamic>>> call() {
    return repository.getMainCategories();
  }
}
