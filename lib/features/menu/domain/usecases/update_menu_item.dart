import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';

class UpdateMenuItem implements UseCase<MenuItemEntity, UpdateMenuItemParams> {
  final MenuRepository repository;
  const UpdateMenuItem(this.repository);

  @override
  Future<Either<Failure, MenuItemEntity>> call(UpdateMenuItemParams params) {
    return repository.updateMenuItem(
      id: params.id,
      name: params.name,
      description: params.description,
      price: params.price,
      categoryId: params.categoryId,
      isAvailable: params.isAvailable,
      isMostPopular: params.isMostPopular,
      isWeekendSpecial: params.isWeekendSpecial,
      imagePath: params.imagePath,
      imageUrl: params.imageUrl,
    );
  }
}

class UpdateMenuItemParams extends Equatable {
  final String id;
  final String? name;
  final String? description;
  final double? price;
  final String? categoryId;
  final bool? isAvailable;
  final bool? isMostPopular;
  final bool? isWeekendSpecial;
  final String? imagePath;
  final String? imageUrl;

  const UpdateMenuItemParams({
    required this.id,
    this.name,
    this.description,
    this.price,
    this.categoryId,
    this.isAvailable,
    this.isMostPopular,
    this.isWeekendSpecial,
    this.imagePath,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, description, price, categoryId, isAvailable, isMostPopular, isWeekendSpecial, imagePath, imageUrl];
}
