import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added for querying parent_id
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

class AdminEditScreen extends StatefulWidget {
  final String? id;
  final MenuItemEntity? item;
  const AdminEditScreen({super.key, this.id, this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final _repo = MenuRepositoryImpl();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _available = true;
  PlatformFile? _imageFile;

  // Category State
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  String? _selectedMainId;
  String? _selectedSubId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Load Main Categories
      final mains = await _repo.getMainCategories();

      if (!mounted) return;
      setState(() => _mainCategories = mains);

      // 2. Pre-fill data if editing
      if (widget.item != null) {
        final item = widget.item!;
        _nameCtrl.text = item.name;
        _descCtrl.text = item.description ?? '';
        _priceCtrl.text = item.price.toString();
        _available = item.isAvailable;

        // 3. Resolve Category Hierarchy
        if (item.categoryId != null) {
          // We have the Sub Category ID (item.categoryId).
          // We must find its PARENT ID to set the Main Dropdown.
          final client = Supabase.instance.client;

          final catResult = await client.from('categories').select('parent_id').eq('id', item.categoryId!).single();

          final parentId = catResult['parent_id'] as String?;

          if (parentId != null) {
            // It has a parent, so fetch the siblings (sub-categories) for this parent
            final subs = await _repo.getSubCategories(parentId);

            if (mounted) {
              setState(() {
                _selectedMainId = parentId; // Select Main
                _subCategories = subs; // Populate Sub List
                _selectedSubId = item.categoryId; // Select Sub
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _onMainCategoryChanged(String? mainId) async {
    setState(() {
      _selectedMainId = mainId;
      _selectedSubId = null;
      _subCategories = [];
    });
    if (mainId != null) {
      final subs = await _repo.getSubCategories(mainId);
      if (mounted) setState(() => _subCategories = subs);
    }
  }

  // Dialog to create new category
  Future<void> _showAddCategoryDialog(bool isMain, {String? parentId}) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMain ? 'New Main Category' : 'New Sub Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              final id = await context.read<AdminProvider>().addCategory(ctrl.text, parentId: parentId);
              if (ctx.mounted) Navigator.pop(ctx);

              // Refresh lists
              if (isMain) {
                final mains = await _repo.getMainCategories();
                setState(() {
                  _mainCategories = mains;
                  _selectedMainId = id;
                  _subCategories = [];
                  _selectedSubId = null;
                });
              } else if (parentId != null) {
                final subs = await _repo.getSubCategories(parentId);
                setState(() {
                  _subCategories = subs;
                  _selectedSubId = id;
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.item == null ? 'New Item' : 'Edit Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                Center(
                  child: InkWell(
                    onTap: () async {
                      final f = await admin.pickImage();
                      if (f != null) setState(() => _imageFile = f);
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: _imageFile != null ? Image.memory(_imageFile!.bytes!, fit: BoxFit.cover) : (widget.item?.imageUrl != null ? CachedNetworkImage(imageUrl: widget.item!.imageUrl!, fit: BoxFit.cover) : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                Text('Category', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                // Main Category Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMainId, // Changed from initialValue to value for updates
                        decoration: const InputDecoration(labelText: 'Main Category', border: OutlineInputBorder()),
                        items: _mainCategories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                        onChanged: _onMainCategoryChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: () => _showAddCategoryDialog(true), tooltip: 'Add Main Category'),
                  ],
                ),
                const SizedBox(height: 16),

                // Sub Category Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubId, // Changed from initialValue to value
                        decoration: const InputDecoration(labelText: 'Sub Category', border: OutlineInputBorder()),
                        items: _subCategories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                        onChanged: (v) => setState(() => _selectedSubId = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      // Only enable if main is selected
                      onPressed: _selectedMainId == null ? null : () => _showAddCategoryDialog(false, parentId: _selectedMainId),
                      tooltip: 'Add Sub Category',
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SwitchListTile(title: const Text('Available for sale'), value: _available, onChanged: (v) => setState(() => _available = v), contentPadding: EdgeInsets.zero),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: admin.loading
                        ? null
                        : () async {
                            final price = double.tryParse(_priceCtrl.text) ?? 0.0;
                            bool success;

                            if (widget.item == null) {
                              success = await admin.create(
                                name: _nameCtrl.text,
                                description: _descCtrl.text,
                                price: price,
                                categoryId: _selectedSubId, // IMPORTANT: Save UUID
                                isAvailable: _available,
                                imageFile: _imageFile,
                              );
                            } else {
                              success = await admin.update(id: widget.item!.id, name: _nameCtrl.text, description: _descCtrl.text, price: price, categoryId: _selectedSubId, isAvailable: _available, imageFile: _imageFile);
                            }

                            if (context.mounted && success) Navigator.pop(context);
                          },
                    child: admin.loading ? const CircularProgressIndicator() : const Text('Save Item'),
                  ),
                ),
                if (admin.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(admin.error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
