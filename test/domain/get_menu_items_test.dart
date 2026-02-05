import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_menu_items.dart';

class _MockRepo extends Mock implements MenuRepository {}

void main() {
  test('GetMenuItems returns list from repository', () async {
    final repo = _MockRepo();
    final usecase = GetMenuItems(repo);
    final items = [MenuItemEntity(id: '1', name: 'Item', description: null, price: 1.0, categoryId: null, categoryName: null, imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now())];

    when(
      () => repo.getMenuItems(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        categoryId: any(named: 'categoryId'),
        categoryIds: any(named: 'categoryIds'),
      ),
    ).thenAnswer((_) async => Right(items));

    final result = await usecase(const GetMenuItemsParams());
    expect(result, Right(items));

    verify(() => repo.getMenuItems(page: 1, pageSize: 10, search: null, categoryId: null, categoryIds: null)).called(1);
  });
}
