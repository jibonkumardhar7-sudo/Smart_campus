import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

class LostFoundFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const LostFoundFormScreen({super.key, this.item});

  @override
  State<LostFoundFormScreen> createState() => _LostFoundFormScreenState();
}

class _LostFoundFormScreenState extends State<LostFoundFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  String _type = 'lost';
  String? _category;
  DateTime _date = DateTime.now();
  File? _image;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _title.text = item['title'] ?? '';
      _description.text = item['description'] ?? '';
      _location.text = item['location'] ?? '';
      _contact.text = item['contact'] ?? '';
      _type = item['type'];
      _category = item['category'];
      _date = DateTime.tryParse(item['item_date'].toString()) ?? DateTime.now();
    } else {
      _contact.text = (AppState.profile?['phone'] ?? '').toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = widget.item?['image_url'];
      if (_image != null) imageUrl = await uploadFile(_image!, 'lost_found');

      final data = {
        'type': _type,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'location': _location.text.trim(),
        'contact': _contact.text.trim(),
        'category': _category,
        'item_date': DateFormat('yyyy-MM-dd').format(_date),
        'image_url': imageUrl,
      };

      if (_isEdit) {
        await supabase.from('lost_found_items').update(data).eq('id', widget.item!['id']);
      } else {
        data['user_id'] = AppState.uid;
        await supabase.from('lost_found_items').insert(data);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Post updated' : 'Post created');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not save. Try again.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Post' : 'New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'lost', label: Text('I lost something')),
                    ButtonSegment(value: 'found', label: Text('I found something')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
              ),
              const SizedBox(height: 16),
              ImagePickerBox(
                file: _image,
                networkUrl: widget.item?['image_url'],
                onTap: () async {
                  final f = await pickImage();
                  if (f != null) setState(() => _image = f);
                },
              ),
              AppTextField(controller: _title, label: 'Item name', icon: Icons.label_outline,
                  validator: (v) => Validators.required(v, 'Item name')),
              AppDropdown(
                label: 'Category',
                value: _category,
                items: AppConfig.lostCategories,
                onChanged: (v) => setState(() => _category = v),
              ),
              AppTextField(controller: _description, label: 'Description', icon: Icons.description_outlined,
                  maxLines: 3, validator: (v) => Validators.required(v, 'Description')),
              AppTextField(controller: _location, label: 'Location', icon: Icons.location_on_outlined,
                  validator: (v) => Validators.required(v, 'Location')),
              AppTextField(controller: _contact, label: 'Contact (phone)', icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone, validator: Validators.phone),
              ListTile(
                tileColor: context.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat('d MMM yyyy').format(_date)}'),
                onTap: () async {
                  final d = await pickDate(context, initial: _date);
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 20),
              AppButton(label: _isEdit ? 'Update' : 'Submit', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}