import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetMainCategories {
  final MenuRepository repository;
  const GetMainCategories(this.repository);

  Future<List<String>> call() {
    return repository.getMainCategories();
  }
}
