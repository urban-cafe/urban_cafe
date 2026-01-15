import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class CreateMenuItem implements UseCase<MenuItemEntity, CreateMenuItemParams> {
  final MenuRepository repository;
  const CreateMenuItem(this.repository);

  @override
  Future<Either<Failure, MenuItemEntity>> call(CreateMenuItemParams params) {
    return repository.createMenuItem(
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

class CreateMenuItemParams extends Equatable {
  final String name;
  final String? description;
  final double price;
  final String? categoryId;
  final bool isAvailable;
  final bool isMostPopular;
  final bool isWeekendSpecial;
  final String? imagePath;
  final String? imageUrl;

  const CreateMenuItemParams({
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.isAvailable = true,
    this.isMostPopular = false,
    this.isWeekendSpecial = false,
    this.imagePath,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, description, price, categoryId, isAvailable, isMostPopular, isWeekendSpecial, imagePath, imageUrl];
}
