import '../repositories/menu_repository.dart';

class GetSubCategories {
  final MenuRepository repository;
  const GetSubCategories(this.repository);

  Future<List<String>> call(String parentName) {
    return repository.getSubCategories(parentName);
  }
}
