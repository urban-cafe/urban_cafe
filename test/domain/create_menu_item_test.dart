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
    final entity = MenuItemEntity(
      id: '1',
      name: 'New',
      description: null,
      price: 2.0,
      category: 'Coffee',
      imagePath: null,
      imageUrl: null,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    when(() => repo.createMenuItem(name: any(named: 'name'), description: any(named: 'description'), price: any(named: 'price'), category: any(named: 'category'), isAvailable: any(named: 'isAvailable'), imagePath: any(named: 'imagePath'), imageUrl: any(named: 'imageUrl')))
        .thenAnswer((_) async => entity);

    final result = await usecase(name: 'New', price: 2.0, category: 'Coffee');
    expect(result, entity);
    verify(() => repo.createMenuItem(name: 'New', description: null, price: 2.0, category: 'Coffee', isAvailable: true, imagePath: null, imageUrl: null)).called(1);
  });
}
