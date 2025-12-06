import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';

class MenuScreen extends StatefulWidget {
  final String? initialMainCategory;
  const MenuScreen({super.key, this.initialMainCategory});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _selectedSubId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MenuProvider>();

      // 1. FIX: Explicitly clear the search in the Provider and UI
      _searchCtrl.clear();
      provider.setSearch('');

      // 2. Initialize the category data
      if (widget.initialMainCategory != null) {
        provider.initForMainCategory(widget.initialMainCategory!);
      } else {
        provider.fetchAdminList(); // Fallback
      }
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<MenuProvider>().loadMore();
      }
    });
  }

  // 3. FIX: Add dispose to clean up controllers (Prevent Memory Leaks)
  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.initialMainCategory ?? 'Menu')),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search items',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    // Fix: Changed from onSubmitted to onChanged for real-time search
                    // or keep onSubmitted if you prefer pressing enter.
                    onChanged: (v) => provider.setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),

                // Sub Category Dropdown
                if (provider.subCategories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedSubId,
                        hint: const Text('Filter'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...provider.subCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedSubId = v);
                          provider.filterBySubCategory(v);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: provider.loading && provider.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: provider.items.length + (provider.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == provider.items.length) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
                        );
                      }
                      final item = provider.items[index];
                      final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

                      return InkWell(
                        onTap: () => context.push('/detail', extra: item),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: item.imageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: item.imageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.fastfood, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (item.categoryName != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(item.categoryName!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(priceFormat.format(item.price), style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                if (!item.isAvailable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Sold Out', style: TextStyle(color: Colors.red.shade700, fontSize: 10)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
