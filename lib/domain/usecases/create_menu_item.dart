import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class CreateMenuItem {
  final MenuRepository repository;
  const CreateMenuItem(this.repository);

  Future<MenuItemEntity> call({required String name, String? description, required double price, String? category, bool isAvailable = true, String? imagePath, String? imageUrl}) {
    return repository.createMenuItem(name: name, description: description, price: price, category: category, isAvailable: isAvailable, imagePath: imagePath, imageUrl: imageUrl);
  }
}
