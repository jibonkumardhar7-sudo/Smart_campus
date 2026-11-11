import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

Color statusColor(String status) {
  switch (status) {
    case 'In Progress':
      return Colors.blue;
    case 'Resolved':
      return Colors.green;
    case 'Rejected':
      return Colors.red;
    default:
      return Colors.orange;
  }
}

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint & Feedback'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Submit'),
            Tab(text: AppState.isAdmin ? 'All Complaints' : 'My Submissions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SubmitTab(onSubmitted: () {
            setState(() => _refreshKey++);
            _tabController.animateTo(1);
          }),
          _TrackTab(key: ValueKey(_refreshKey)),
        ],
      ),
    );
  }
}

class _SubmitTab extends StatefulWidget {
  final VoidCallback onSubmitted;
  const _SubmitTab({required this.onSubmitted});

  @override
  State<_SubmitTab> createState() => _SubmitTabState();
}

class _SubmitTabState extends State<_SubmitTab> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _type = 'complaint';
  String? _category;
  File? _image;
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl;
      if (_image != null) imageUrl = await uploadFile(_image!, 'complaints');
      await supabase.from('complaints').insert({
        'user_id': AppState.uid,
        'type': _type,
        'category': _category,
        'description': _description.text.trim(),
        'image_url': imageUrl,
      });
      if (!mounted) return;
      showMessage(context, 'Submitted successfully');
      _description.clear();
      setState(() {
        _image = null;
        _category = null;
      });
      widget.onSubmitted();
    } catch (e) {
      if (mounted) showMessage(context, 'Could not submit. Try again.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'complaint', label: Text('Complaint')),
                  ButtonSegment(value: 'feedback', label: Text('Feedback')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 16),
            AppDropdown(
              label: 'Category',
              value: _category,
              items: AppConfig.complaintCategories,
              onChanged: (v) => setState(() => _category = v),
            ),
            AppTextField(
              controller: _description,
              label: 'Describe your $_type',
              maxLines: 5,
              validator: (v) => Validators.required(v, 'Description'),
            ),
            ImagePickerBox(
              file: _image,
              onTap: () async {
                final f = await pickImage();
                if (f != null) setState(() => _image = f);
              },
            ),
            AppButton(label: 'Submit', loading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _TrackTab extends StatefulWidget {
  const _TrackTab({super.key});

  @override
  State<_TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<_TrackTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('complaints')
          .select('*, profiles(full_name, student_id)')
          .order('created_at', ascending: false);
      _list = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load complaints.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changeStatus(Map<String, dynamic> c, String status) async {
    try {
      await supabase.from('complaints').update({'status': status}).eq('id', c['id']);
      if (mounted) showMessage(context, 'Status updated');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, 'Only admins can change the status.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load);
    if (_list.isEmpty) return const EmptyView(message: 'Nothing submitted yet', icon: Icons.feedback_outlined);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (context, i) {
          final c = _list[i];
          final owner = c['profiles'] as Map<String, dynamic>?;
          return Card(
            color: context.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${c['type'].toString().toUpperCase()} • ${c['category']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      StatusBadge(text: c['status'], color: statusColor(c['status'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c['description']),
                  if (c['image_url'] != null && c['image_url'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(c['image_url'], height: 120, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${AppState.isAdmin ? '${owner?['full_name'] ?? ''} (${owner?['student_id'] ?? ''}) • ' : ''}${formatDate(c['created_at'])}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (AppState.isAdmin && c['type'] == 'complaint')
                    DropdownButton<String>(
                      value: c['status'],
                      isExpanded: true,
                      items: AppConfig.complaintStatuses
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null && v != c['status']) _changeStatus(c, v);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}