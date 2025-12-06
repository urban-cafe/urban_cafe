import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/domain/usecases/create_menu_item.dart';

class _MockRepo extends Mock implements MenuRepository {}

void main() {
  test('CreateMenuItem calls repo and returns entity', () async {
    final repo = _MockRepo();
    final usecase = CreateMenuItem(repo);
    final entity = MenuItemEntity(id: '1', name: 'New', description: null, price: 2.0, categoryId: 'cat-uuid', categoryName: 'Coffee', imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

    // Fix: Update mock to use categoryId
    when(
      () => repo.createMenuItem(
        name: any(named: 'name'),
        description: any(named: 'description'),
        price: any(named: 'price'),
        categoryId: any(named: 'categoryId'),
        isAvailable: any(named: 'isAvailable'),
        imagePath: any(named: 'imagePath'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => entity);

    // Fix: Call usecase with categoryId
    final result = await usecase(name: 'New', price: 2.0, categoryId: 'cat-uuid');

    expect(result, entity);

    // Fix: Verify with categoryId
    verify(() => repo.createMenuItem(name: 'New', description: null, price: 2.0, categoryId: 'cat-uuid', isAvailable: true, imagePath: null, imageUrl: null)).called(1);
  });
}
