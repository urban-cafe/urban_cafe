import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class DeleteMenuItem {
  final MenuRepository repository;
  const DeleteMenuItem(this.repository);

  Future<void> call(String id) {
    return repository.deleteMenuItem(id);
  }
}
