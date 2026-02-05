import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';

class GetCategoryByName implements UseCase<Category?, GetCategoryByNameParams> {
  final MenuRepository repository;
  const GetCategoryByName(this.repository);

  @override
  Future<Either<Failure, Category?>> call(GetCategoryByNameParams params) {
    return repository.getCategoryByName(params.name);
  }
}

class GetCategoryByNameParams extends Equatable {
  final String name;
  const GetCategoryByNameParams(this.name);

  @override
  List<Object?> get props => [name];
}
