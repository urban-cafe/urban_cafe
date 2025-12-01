import '../repositories/menu_repository.dart';

class GetCategories {
  final MenuRepository repository;
  const GetCategories(this.repository);

  Future<List<String>> call() {
    return repository.getCategories();
  }
}
