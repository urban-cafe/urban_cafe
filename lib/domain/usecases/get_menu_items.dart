import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetMenuItems implements UseCase<List<MenuItemEntity>, GetMenuItemsParams> {
  final MenuRepository repository;
  const GetMenuItems(this.repository);

  @override
  Future<Either<Failure, List<MenuItemEntity>>> call(GetMenuItemsParams params) {
    return repository.getMenuItems(
      page: params.page,
      pageSize: params.pageSize,
      search: params.search,
      categoryId: params.categoryId,
      categoryIds: params.categoryIds,
    );
  }
}

class GetMenuItemsParams extends Equatable {
  final int page;
  final int pageSize;
  final String? search;
  final String? categoryId;
  final List<String>? categoryIds;

  const GetMenuItemsParams({
    this.page = 1,
    this.pageSize = 10,
    this.search,
    this.categoryId,
    this.categoryIds,
  });

  @override
  List<Object?> get props => [page, pageSize, search, categoryId, categoryIds];
}
