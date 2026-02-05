import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';

class GetFavoriteItems implements UseCase<List<MenuItemEntity>, NoParams> {
  final MenuRepository repository;

  GetFavoriteItems(this.repository);

  @override
  Future<Either<Failure, List<MenuItemEntity>>> call(NoParams params) async {
    return await repository.getFavoriteItems();
  }
}
