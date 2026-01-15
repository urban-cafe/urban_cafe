import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/category.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetSubCategories implements UseCase<List<Category>, GetSubCategoriesParams> {
  final MenuRepository repository;
  const GetSubCategories(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(GetSubCategoriesParams params) {
    return repository.getSubCategories(params.parentId);
  }
}

class GetSubCategoriesParams extends Equatable {
  final String parentId;
  const GetSubCategoriesParams(this.parentId);

  @override
  List<Object?> get props => [parentId];
}
