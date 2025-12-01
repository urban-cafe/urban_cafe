import 'package:flutter/material.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/widgets/menu_card.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItemEntity> items;
  final void Function(MenuItemEntity)? onTap;
  final ScrollController? scrollController;
  const MenuGrid({super.key, required this.items, this.onTap, this.scrollController});

  int _columnsForWidth(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    // Mobile-first: ensure at least 2 columns on phones
    return 2;
  }

  double _aspectForWidth(double width) {
    if (width < 480) return 0.9;
    if (width < 900) return 1.0;
    return 1.1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columnsForWidth(constraints.maxWidth);
        final aspect = _aspectForWidth(constraints.maxWidth);
        return GridView.builder(
          controller: scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: aspect),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MenuCard(item: item, onTap: () => onTap?.call(item));
          },
        );
      },
    );
  }
}
