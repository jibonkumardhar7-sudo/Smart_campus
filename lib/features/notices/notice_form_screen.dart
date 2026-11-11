import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';


class NoticeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? notice;
  const NoticeFormScreen({super.key, this.notice});

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _category;
  bool _saving = false;

  bool get _isEdit => widget.notice != null;

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      _title.text = widget.notice!['title'];
      _body.text = widget.notice!['body'] ?? '';
      _category = widget.notice!['category'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'category': _category,
      };
      if (_isEdit) {
        await supabase.from('notices').update(data).eq('id', widget.notice!['id']);
      } else {
        data['created_by'] = AppState.uid;
        await supabase.from('notices').insert(data);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Notice updated' : 'Notice published');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Not allowed or something went wrong.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Notice' : 'Add Notice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(controller: _title, label: 'Title', icon: Icons.title,
                  validator: (v) => Validators.required(v, 'Title')),
              AppDropdown(
                label: 'Category',
                value: _category,
                items: AppConfig.noticeCategories,
                onChanged: (v) => setState(() => _category = v),
              ),
              AppTextField(controller: _body, label: 'Notice details', maxLines: 8,
                  validator: (v) => Validators.required(v, 'Details')),
              AppButton(label: _isEdit ? 'Update' : 'Publish', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
