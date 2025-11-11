import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../core/categories.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sku;
  String? _selectedCategory;
  String? _selectedSubcategory;
  late final TextEditingController _tags;
  late final TextEditingController _discount;
  String _status = 'active';
  XFile? _picked;
  bool _uploading = false;
  bool _saving = false;
  Product? _editingProduct;
  bool _loadingProduct = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _desc = TextEditingController();
    _price = TextEditingController();
    _stock = TextEditingController();
    _imageUrl = TextEditingController();
  _sku = TextEditingController();
  _tags = TextEditingController();
  _discount = TextEditingController();

    if (widget.productId != null) {
      _loadProduct(widget.productId!);
    }
  }

  Future<void> _loadProduct(String id) async {
    setState(() => _loadingProduct = true);
    try {
      final svc = ref.read(productServiceProvider);
      final p = await svc.fetch(id);
      if (p != null) {
        _editingProduct = p;
        _title.text = p.title;
        _desc.text = p.description;
        _price.text = p.price.toString();
        _stock.text = p.stock.toString();
        _imageUrl.text = p.imageUrls.isNotEmpty ? p.imageUrls.first : '';
  _sku.text = p.sku;
  _selectedCategory = p.category.isNotEmpty ? p.category : null;
  _selectedSubcategory = p.subcategory.isNotEmpty ? p.subcategory : null;
        _tags.text = p.tags.join(', ');
        _discount.text = p.discount.toString();
        _status = p.status;
      }
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load error: $e')));
      });
    } finally {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
  _sku.dispose();
    _tags.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
      final svc = ref.read(productServiceProvider);
      // If a new image was picked but not yet uploaded, upload it first
      if (_picked != null && (_imageUrl.text.trim().isEmpty)) {
        setState(() => _uploading = true);
        final storage = ref.read(storageServiceProvider);
        final url = await storage.uploadProductImage(_picked!, uid);
        _imageUrl.text = url;
        setState(() => _uploading = false);
      }
      final p = Product(
        id: _editingProduct?.id ?? '',
        sellerId: uid,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: double.parse(_price.text),
  discount: double.tryParse(_discount.text) ?? 0,
  sku: _sku.text.trim(),
  category: _selectedCategory ?? '',
  subcategory: _selectedSubcategory ?? '',
        tags: _tags.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        stock: int.parse(_stock.text),
  imageUrls: _imageUrl.text.trim().isEmpty ? [] : [_imageUrl.text.trim()],
        ratingAvg: _editingProduct?.ratingAvg ?? 0,
        ratingCount: _editingProduct?.ratingCount ?? 0,
        createdAt: _editingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        status: _status,
      );
      if (_editingProduct == null) {
        await svc.create(p);
      } else {
        await svc.update(p);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProduct) {
      return Scaffold(appBar: AppBar(title: const Text('Edit Product')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.productId == null ? 'Add Product' : 'Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v ?? '') ?? -1) >= 0 ? null : 'Enter valid price',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? -1) >= 0 ? null : 'Enter valid stock',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _picked != null
                        ? FutureBuilder<Uint8List>(
                            future: _picked!.readAsBytes(),
                            builder: (context, snap) {
                              if (snap.hasData) {
                                return Image.memory(snap.data!, height: 120, fit: BoxFit.cover);
                              }
                              return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                            },
                          )
                        : (_imageUrl.text.isNotEmpty
                            ? Image.network(_imageUrl.text, height: 120, fit: BoxFit.cover)
                            : const SizedBox(height: 120, child: ColoredBox(color: Colors.black12))),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
                          if (picked == null) return;
                          setState(() => _picked = picked);
                          // Upload immediately
                          final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
                          setState(() => _uploading = true);
                          try {
                            final storage = ref.read(storageServiceProvider);
                            final url = await storage.uploadProductImage(picked, uid);
                            _imageUrl.text = url;
                          } catch (e) {
                            if (!mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
                            });
                          } finally {
                            if (mounted) setState(() => _uploading = false);
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _uploading ? null : () async {
                          if (_picked == null) return;
                          final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
                          setState(() => _uploading = true);
                          try {
                            final storage = ref.read(storageServiceProvider);
                            final url = await storage.uploadProductImage(_picked!, uid);
                            _imageUrl.text = url;
                            if (!mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded')));
                            });
                          } catch (e) {
                            if (!mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
                            });
                          } finally {
                            if (mounted) setState(() => _uploading = false);
                          }
                        },
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(_uploading ? 'Uploading...' : 'Upload'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Allow entering an image URL manually
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sku,
                decoration: const InputDecoration(labelText: 'SKU / Product Code'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: productCategories.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCategory = v;
                  // reset subcategory when category changes
                  _selectedSubcategory = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubcategory,
                decoration: const InputDecoration(labelText: 'Subcategory'),
                items: (_selectedCategory != null ? productCategories[_selectedCategory] : <String>[])!
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubcategory = v),
                validator: (v) {
                  // Subcategory optional, but if category has entries, ensure selection
                  final options = _selectedCategory != null ? productCategories[_selectedCategory] : null;
                  if (options != null && options.isNotEmpty && (v == null || v.isEmpty)) return 'Select a subcategory';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discount,
                decoration: const InputDecoration(labelText: 'Discount (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'out_of_stock', child: Text('Out of stock')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
