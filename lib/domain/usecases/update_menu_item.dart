import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class UpdateMenuItem {
  final MenuRepository repository;
  const UpdateMenuItem(this.repository);

  Future<MenuItemEntity> call({
    required String id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    String? imagePath,
    String? imageUrl,
  }) {
    return repository.updateMenuItem(
      id: id,
      name: name,
      description: description,
      price: price,
      category: category,
      isAvailable: isAvailable,
      imagePath: imagePath,
      imageUrl: imageUrl,
    );
  }
}
