import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetFavorites implements UseCase<List<String>, NoParams> {
  final MenuRepository repository;

  GetFavorites(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getFavorites();
  }
}
