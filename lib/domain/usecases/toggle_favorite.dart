import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class ToggleFavorite implements UseCase<void, String> {
  final MenuRepository repository;

  ToggleFavorite(this.repository);

  @override
  Future<Either<Failure, void>> call(String menuItemId) async {
    return await repository.toggleFavorite(menuItemId);
  }
}
