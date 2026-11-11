import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

class MarketplaceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const MarketplaceFormScreen({super.key, this.item});

  @override
  State<MarketplaceFormScreen> createState() => _MarketplaceFormScreenState();
}

class _MarketplaceFormScreenState extends State<MarketplaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String? _category;
  String? _condition;
  File? _image;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _title.text = item['title'];
      _description.text = item['description'] ?? '';
      _price.text = item['price'].toString();
      _category = item['category'];
      _condition = item['condition'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = widget.item?['image_url'];
      if (_image != null) imageUrl = await uploadFile(_image!, 'marketplace');

      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'price': double.parse(_price.text.trim()),
        'category': _category,
        'condition': _condition,
        'image_url': imageUrl,
      };
      if (_isEdit) {
        await supabase.from('marketplace_items').update(data).eq('id', widget.item!['id']);
      } else {
        data['user_id'] = AppState.uid;
        await supabase.from('marketplace_items').insert(data);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Listing updated' : 'Listing created');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not save. Try again.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Listing' : 'Post Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerBox(
                file: _image,
                networkUrl: widget.item?['image_url'],
                label: 'Add Product Image',
                onTap: () async {
                  final f = await pickImage();
                  if (f != null) setState(() => _image = f);
                },
              ),
              AppTextField(controller: _title, label: 'Product title', icon: Icons.label_outline,
                  validator: (v) => Validators.required(v, 'Title')),
              AppTextField(controller: _description, label: 'Description', maxLines: 3,
                  validator: (v) => Validators.required(v, 'Description')),
              AppTextField(controller: _price, label: 'Price (৳)', icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number, validator: Validators.price),
              AppDropdown(label: 'Category', value: _category, items: AppConfig.marketCategories,
                  onChanged: (v) => setState(() => _category = v)),
              AppDropdown(label: 'Condition', value: _condition,
                  items: const ['New', 'Like New', 'Good Condition', 'Used'],
                  onChanged: (v) => setState(() => _condition = v)),
              const SizedBox(height: 10),
              AppButton(label: _isEdit ? 'Update' : 'Post', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
