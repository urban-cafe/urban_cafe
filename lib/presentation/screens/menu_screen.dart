import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/presentation/screens/menu_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final String? initialMainCategory;
  const MenuScreen({super.key, this.initialMainCategory});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _mainCategory;
  String? _subCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menu = context.read<MenuProvider>();
      _mainCategory = widget.initialMainCategory;
      if (_mainCategory == 'FOOD') {
        menu.setCategory('Food');
      } else if (_mainCategory == 'HOT DRINKS') {
        _subCategory = 'Coffee';
        menu.setCategory('Coffee');
      } else if (_mainCategory == 'COLD DRINKS') {
        menu.fetchSubCategories('COLD DRINKS').then((_) {
          setState(() {
            _subCategory = 'All';
          });
          context.read<MenuProvider>().setCategories(context.read<MenuProvider>().subCategories);
        });
      } else {
        menu.fetch();
      }
      menu.fetchCategories();
    });
    _scrollCtrl.addListener(() {
      final provider = context.read<MenuProvider>();
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        provider.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('UrbanCafe Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin',
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isConfigured) {
                Navigator.pushNamed(context, '/admin/login');
                return;
              }
              if (auth.isLoggedIn) {
                Navigator.pushNamed(context, '/admin');
              } else {
                Navigator.pushNamed(context, '/admin/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search menu'),
                    onSubmitted: (v) => provider.setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),
                if (_mainCategory == 'COLD DRINKS')
                  DropdownButton<String?>(
                    value: _subCategory,
                    hint: const Text('Subcategory'),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All')),
                      ...context.watch<MenuProvider>().subCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) {
                      setState(() => _subCategory = v);
                      if (v == null || v == 'All') {
                        provider.setCategories(provider.subCategories);
                      } else {
                        provider.setCategory(v);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(child: Text(provider.error!))
                  : ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: provider.items.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => MenuDetailScreen(item: item))),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: item.imageUrl != null ? Image.network(item.imageUrl!, fit: BoxFit.contain) : Container(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(priceFormat.format(item.price), style: Theme.of(context).textTheme.titleSmall),
                                            const Spacer(),
                                            Icon(item.isAvailable ? Icons.check_circle : Icons.cancel, color: item.isAvailable ? Colors.green : Colors.red, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (provider.loadingMore) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
