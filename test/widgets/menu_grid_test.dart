import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/widgets/menu_grid.dart';

void main() {
  testWidgets('MenuGrid shows item names', (tester) async {
    final now = DateTime.now();
    final items = [
      MenuItemEntity(id: '1', name: 'Espresso', description: '', price: 2.99, category: 'Coffee', imagePath: null, imageUrl: null, isAvailable: true, createdAt: now, updatedAt: now),
      MenuItemEntity(id: '2', name: 'Cappuccino', description: '', price: 3.99, category: 'Coffee', imagePath: null, imageUrl: null, isAvailable: true, createdAt: now, updatedAt: now),
    ];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MenuGrid(items: items))));
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('Cappuccino'), findsOneWidget);
  });
}
