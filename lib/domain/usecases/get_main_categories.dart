import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/category.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetMainCategories implements UseCase<List<Category>, NoParams> {
  final MenuRepository repository;
  const GetMainCategories(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) {
    return repository.getMainCategories();
  }
}
