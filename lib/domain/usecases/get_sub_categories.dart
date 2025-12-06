import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetSubCategories {
  final MenuRepository repository;
  const GetSubCategories(this.repository);

  Future<List<Map<String, dynamic>>> call(String parentId) {
    return repository.getSubCategories(parentId);
  }
}
