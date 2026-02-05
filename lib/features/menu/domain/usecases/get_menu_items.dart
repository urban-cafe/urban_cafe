import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';

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
      isMostPopular: params.isMostPopular,
      isWeekendSpecial: params.isWeekendSpecial,
    );
  }
}

class GetMenuItemsParams extends Equatable {
  final int page;
  final int pageSize;
  final String? search;
  final String? categoryId;
  final List<String>? categoryIds;
  final bool? isMostPopular;
  final bool? isWeekendSpecial;

  const GetMenuItemsParams({
    this.page = 1,
    this.pageSize = 10,
    this.search,
    this.categoryId,
    this.categoryIds,
    this.isMostPopular,
    this.isWeekendSpecial,
  });

  @override
  List<Object?> get props => [page, pageSize, search, categoryId, categoryIds, isMostPopular, isWeekendSpecial];
}
