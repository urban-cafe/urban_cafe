import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/domain/usecases/get_menu_items.dart';

class _MockRepo extends Mock implements MenuRepository {}

void main() {
  test('GetMenuItems returns list from repository', () async {
    final repo = _MockRepo();
    final usecase = GetMenuItems(repo);
    final items = [MenuItemEntity(id: '1', name: 'Item', description: null, price: 1.0, categoryId: null, categoryName: null, imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now())];

    // Fix: Update mock to match new signature
    when(
      () => repo.getMenuItems(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        categoryId: any(named: 'categoryId'),
        categoryIds: any(named: 'categoryIds'),
      ),
    ).thenAnswer((_) async => items);

    final result = await usecase();
    expect(result, items);

    // Fix: Verify with new parameters
    verify(() => repo.getMenuItems(page: 1, pageSize: 10, search: null, categoryId: null, categoryIds: null)).called(1);
  });
}
