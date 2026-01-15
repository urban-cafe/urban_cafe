import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

    when(
      () => repo.createMenuItem(
        name: any(named: 'name'),
        description: any(named: 'description'),
        price: any(named: 'price'),
        categoryId: any(named: 'categoryId'),
        isAvailable: any(named: 'isAvailable'),
        imagePath: any(named: 'imagePath'),
        imageUrl: any(named: 'imageUrl'),
        isMostPopular: any(named: 'isMostPopular'),
        isWeekendSpecial: any(named: 'isWeekendSpecial'),
      ),
    ).thenAnswer((_) async => Right(entity));

    final result = await usecase(const CreateMenuItemParams(name: 'New', price: 2.0, categoryId: 'cat-uuid'));

    expect(result, Right(entity));

    verify(() => repo.createMenuItem(
      name: 'New', 
      description: null, 
      price: 2.0, 
      categoryId: 'cat-uuid', 
      isAvailable: true, 
      isMostPopular: false,
      isWeekendSpecial: false,
      imagePath: null, 
      imageUrl: null
    )).called(1);
  });
}
