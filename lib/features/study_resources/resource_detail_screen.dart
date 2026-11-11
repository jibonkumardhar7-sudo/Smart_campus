import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'resource_form_screen.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> resource;
  const ResourceDetailScreen({super.key, required this.resource});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  late Map<String, dynamic> _resource;

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
  }

  bool get _isOwner => _resource['user_id'] == AppState.uid;

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Delete resource', 'Do you really want to delete this resource?');
    if (!ok) return;
    try {
      await supabase.from('study_resources').delete().eq('id', _resource['id']);
      if (!mounted) return;
      showMessage(context, 'Resource deleted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not delete.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _resource['file_size'] == null
        ? ''
        : '${(_resource['file_size'] / (1024 * 1024)).toStringAsFixed(1)} MB';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Details'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ResourceFormScreen(resource: _resource)));
                final fresh = await supabase.from('study_resources').select().eq('id', _resource['id']).maybeSingle();
                if (fresh != null && mounted) setState(() => _resource = fresh);
              },
            ),
          if (_isOwner || AppState.isAdmin) IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: Icon(Icons.picture_as_pdf, size: 80, color: Colors.red)),
          const SizedBox(height: 12),
          Text(_resource['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_resource['description'] ?? ''),
          const SizedBox(height: 14),
          InfoRow(icon: Icons.school_outlined, text: 'Department: ${_resource['department']}'),
          InfoRow(icon: Icons.timeline, text: 'Semester: ${_resource['semester']}'),
          InfoRow(icon: Icons.category_outlined, text: 'Category: ${_resource['category']}'),
          if (size.isNotEmpty) InfoRow(icon: Icons.sd_storage_outlined, text: 'Size: $size'),
          InfoRow(icon: Icons.calendar_today, text: 'Uploaded: ${formatDate(_resource['created_at'])}'),
          const SizedBox(height: 24),
          AppButton(
            label: 'Download / Open PDF',
            icon: Icons.download,
            onPressed: () => openLink(context, _resource['file_url']),
          ),
        ],
      ),
    );
  }
}
