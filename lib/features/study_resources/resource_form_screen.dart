import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

class ResourceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? resource;
  const ResourceFormScreen({super.key, this.resource});

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _department;
  String? _semester;
  String? _category;
  File? _pdf;
  bool _saving = false;

  bool get _isEdit => widget.resource != null;

  @override
  void initState() {
    super.initState();
    final r = widget.resource;
    if (r != null) {
      _title.text = r['title'];
      _description.text = r['description'] ?? '';
      _department = r['department'];
      _semester = r['semester'];
      _category = r['category'];
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;
    setState(() => _pdf = File(result.files.single.path!));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _pdf == null) {
      showMessage(context, 'Please choose a PDF file', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'department': _department,
        'semester': _semester,
        'category': _category,
      };
      if (_pdf != null) {
        data['file_url'] = await uploadFile(_pdf!, 'resources');
        data['file_size'] = _pdf!.lengthSync();
      }
      if (_isEdit) {
        await supabase.from('study_resources').update(data).eq('id', widget.resource!['id']);
      } else {
        data['user_id'] = AppState.uid;
        await supabase.from('study_resources').insert(data);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Resource updated' : 'Resource uploaded');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Upload failed. Try again.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Resource' : 'Upload Resource')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(controller: _title, label: 'Title', icon: Icons.title,
                  validator: (v) => Validators.required(v, 'Title')),
              AppTextField(controller: _description, label: 'Description', maxLines: 3,
                  validator: (v) => Validators.required(v, 'Description')),
              AppDropdown(label: 'Department', value: _department, items: AppConfig.departments,
                  onChanged: (v) => setState(() => _department = v)),
              AppDropdown(label: 'Semester', value: _semester, items: AppConfig.semesters,
                  onChanged: (v) => setState(() => _semester = v)),
              AppDropdown(label: 'Category', value: _category, items: AppConfig.resourceCategories,
                  onChanged: (v) => setState(() => _category = v)),
              ListTile(
                tileColor: context.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(_pdf == null
                    ? (_isEdit ? 'Keep current file (tap to replace)' : 'Choose PDF file')
                    : _pdf!.path.split('/').last),
                onTap: _pickPdf,
              ),
              const SizedBox(height: 20),
              AppButton(label: _isEdit ? 'Update' : 'Upload', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}