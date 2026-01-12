import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/widgets/add_category_dialog.dart';

class AdminEditScreen extends StatefulWidget {
  final String? id;
  final MenuItemEntity? item;
  const AdminEditScreen({super.key, this.id, this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MenuRepositoryImpl();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _available = true;
  bool _isMostPopular = false;
  bool _isWeekendSpecial = false;
  PlatformFile? _imageFile;

  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  String? _selectedMainId;
  String? _selectedSubId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final mains = await _repo.getMainCategories();
      if (!mounted) return;
      setState(() => _mainCategories = mains);

      if (widget.item != null) {
        final item = widget.item!;
        _nameCtrl.text = item.name;
        _descCtrl.text = item.description ?? '';
        _priceCtrl.text = item.price.toString();
        _available = item.isAvailable;
        _isMostPopular = item.isMostPopular;
        _isWeekendSpecial = item.isWeekendSpecial;

        if (item.categoryId != null) {
          final client = Supabase.instance.client;
          final catResult = await client.from('categories').select('parent_id').eq('id', item.categoryId!).single();
          final parentId = catResult['parent_id'] as String?;

          if (parentId != null) {
            final subs = await _repo.getSubCategories(parentId);
            if (mounted) {
              setState(() {
                _selectedMainId = parentId;
                _subCategories = subs;
                _selectedSubId = item.categoryId;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  Future<void> _triggerAddCategory({String? parentId}) async {
    final newId = await showAddCategoryDialog(context, parentId: parentId);

    if (newId != null && mounted) {
      if (parentId == null) {
        final mains = await _repo.getMainCategories();
        setState(() {
          _mainCategories = mains;
          _selectedMainId = newId;
          _subCategories = [];
          _selectedSubId = null;
        });
      } else {
        final subs = await _repo.getSubCategories(parentId);
        setState(() {
          _subCategories = subs;
          _selectedSubId = newId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.item == null ? 'New Item' : 'Edit Item',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.colorScheme.onSurface),
          ),
        ),
        body: Skeletonizer(
          enabled: isLoading,
          // Fixed: Replaced withOpacity with withValues
          effect: ShimmerEffect(baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), highlightColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker
                      Center(
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () async {
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

                      // Name Field
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                        validator: (v) => AppValidators.required(v, 'Item Name'),
                      ),
                      const SizedBox(height: 16),

                      // Price Field
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                        validator: (v) => AppValidators.number(v, 'Price'),
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),

                      Text('Category', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),

                      // Main Category Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedMainId,
                              decoration: const InputDecoration(labelText: 'Main Category', border: OutlineInputBorder()),
                              items: isLoading ? [const DropdownMenuItem(value: 'loading', child: Text('Loading Category...'))] : _mainCategories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                              onChanged: isLoading ? null : _onMainCategoryChanged,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: () => _triggerAddCategory(), tooltip: 'Add Main Category'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sub Category Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubId,
                              decoration: const InputDecoration(labelText: 'Sub Category', border: OutlineInputBorder()),
                              items: isLoading ? [const DropdownMenuItem(value: 'loading', child: Text('Loading Subcategory...'))] : _subCategories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                              onChanged: isLoading ? null : (v) => setState(() => _selectedSubId = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            onPressed: _selectedMainId == null ? null : () => _triggerAddCategory(parentId: _selectedMainId),
                            tooltip: 'Add Sub Category',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      SwitchListTile(title: const Text('Available for sale'), value: _available, onChanged: (v) => setState(() => _available = v), contentPadding: EdgeInsets.zero),
                      SwitchListTile(title: const Text('Most Popular'), value: _isMostPopular, onChanged: (v) => setState(() => _isMostPopular = v), contentPadding: EdgeInsets.zero),
                      SwitchListTile(title: const Text('Weekend Special'), value: _isWeekendSpecial, onChanged: (v) => setState(() => _isWeekendSpecial = v), contentPadding: EdgeInsets.zero),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: admin.loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  if (_selectedSubId == null && _selectedMainId == null) {
                                    showAppSnackBar(context, "Please select a category", isError: true);
                                    return;
                                  }
                                  final price = double.tryParse(_priceCtrl.text) ?? 0.0;
                                  bool success;
                                  if (widget.item == null) {
                                    success = await admin.create(name: _nameCtrl.text, description: _descCtrl.text, price: price, categoryId: _selectedSubId, isAvailable: _available, isMostPopular: _isMostPopular, isWeekendSpecial: _isWeekendSpecial, imageFile: _imageFile);
                                  } else {
                                    success = await admin.update(id: widget.item!.id, name: _nameCtrl.text, description: _descCtrl.text, price: price, categoryId: _selectedSubId, isAvailable: _available, isMostPopular: _isMostPopular, isWeekendSpecial: _isWeekendSpecial, imageFile: _imageFile);
                                  }
                                  if (!context.mounted) return;
                                  if (success) {
                                    showAppSnackBar(context, widget.item == null ? "Created Successfully" : "Updated Successfully");
                                    context.pop(true); // Return true to indicate change
                                  }
                                },
                          child: admin.loading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2.5)) : const Text('Save Item'),
                        ),
                      ),

                      if (admin.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(admin.error!, style: TextStyle(color: theme.colorScheme.error)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
