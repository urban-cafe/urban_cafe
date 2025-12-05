import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';

class AdminEditScreen extends StatefulWidget {
  final String? id;
  final MenuItemEntity? item;
  const AdminEditScreen({super.key, this.id, this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _category;
  String? _mainCat;
  String? _subCat;
  bool _available = true;
  PlatformFile? _imageFile;
  MenuItemEntity? _existing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _existing = widget.item ?? (widget.id != null ? context.read<MenuProvider>().items.where((e) => e.id == widget.id).cast<MenuItemEntity?>().firstOrNull : null);
      if (_existing != null) {
        _nameCtrl.text = _existing!.name;
        _descCtrl.text = _existing!.description ?? '';
        _priceCtrl.text = _existing!.price.toStringAsFixed(2);
        _category = _existing!.category;
        _available = _existing!.isAvailable;
        if (_category == 'Coffee') {
          _mainCat = 'HOT DRINKS';
          _subCat = 'Coffee';
        } else if (_category == 'Food') {
          _mainCat = 'FOOD';
          _subCat = null;
        } else if (_category != null) {
          _mainCat = 'COLD DRINKS';
          _subCat = _category;
          context.read<MenuProvider>().fetchSubCategories('COLD DRINKS');
        }
        setState(() {});
      }
      final menu = context.read<MenuProvider>();
      menu.fetchCategories();
      menu.fetchMainCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null && widget.item == null ? 'Add Item' : 'Edit Item')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final form = Expanded(
                  flex: isWide ? 2 : 0,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final menu = context.watch<MenuProvider>();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String?>(
                                value: _mainCat,
                                decoration: const InputDecoration(labelText: 'Main Category'),
                                items: menu.mainCategories.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))).toList(),
                                onChanged: (v) async {
                                  setState(() {
                                    _mainCat = v;
                                    _subCat = null;
                                    _category = null;
                                  });
                                  if (v == 'COLD DRINKS') {
                                    await context.read<MenuProvider>().fetchSubCategories('COLD DRINKS');
                                  } else if (v == 'HOT DRINKS') {
                                    setState(() {
                                      _subCat = 'Coffee';
                                      _category = 'Coffee';
                                    });
                                  } else if (v == 'FOOD') {
                                    setState(() {
                                      _category = 'Food';
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_mainCat == 'COLD DRINKS')
                                DropdownButtonFormField<String?>(
                                  value: _subCat,
                                  decoration: const InputDecoration(labelText: 'Sub Category'),
                                  items: context.watch<MenuProvider>().subCategories.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _subCat = v;
                                      _category = v;
                                    });
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(value: _available, title: const Text('Available'), onChanged: (v) => setState(() => _available = v)),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: admin.loading
                                ? null
                                : () async {
                                    final price = double.tryParse(_priceCtrl.text) ?? 0;
                                    if (widget.id == null && widget.item == null) {
                                      final res = await admin.create(name: _nameCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(), price: price, category: _category, isAvailable: _available, imageFile: _imageFile);
                                      log("Create menu item result: $res");
                                      if (res != null) Navigator.pop(context);
                                    } else {
                                      final id = widget.item?.id ?? widget.id!;
                                      final res = await admin.update(id: id, name: _nameCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(), price: price, category: _category, isAvailable: _available, imageFile: _imageFile);
                                      if (res != null) Navigator.pop(context);
                                    }
                                  },
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          OutlinedButton.icon(
                            onPressed: admin.loading
                                ? null
                                : () async {
                                    final picked = await admin.pickImage();
                                    if (picked != null) setState(() => _imageFile = picked);
                                  },
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          OutlinedButton.icon(onPressed: admin.loading || _imageFile == null ? null : () => setState(() => _imageFile = null), icon: const Icon(Icons.clear), label: const Text('Clear Image')),
                        ],
                      ),
                      if (admin.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(admin.error!)),
                    ],
                  ),
                );
                final preview = Expanded(
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200),
                    clipBehavior: Clip.antiAlias,
                    child: _imageFile != null ? (_imageFile!.bytes != null ? Image.memory(_imageFile!.bytes!, fit: BoxFit.cover) : Center(child: Text(_imageFile!.name))) : (_existing?.imageUrl != null ? CachedNetworkImage(imageUrl: _existing!.imageUrl!, fit: BoxFit.cover) : const Center(child: Text('No image selected'))),
                  ),
                );
                return isWide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [form, const SizedBox(width: 24), preview]) : Column(children: [form, const SizedBox(height: 24), preview]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
