import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'resource_detail_screen.dart';
import 'resource_form_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<Map<String, dynamic>> _resources = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';
  String _department = 'All';
  String _search = '';

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
      final data = await supabase.from('study_resources').select().order('created_at', ascending: false);
      _resources = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load resources.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    return _resources.where((r) {
      if (_category != 'All' && r['category'] != _category) return false;
      if (_department != 'All' && r['department'] != _department) return false;
      if (_search.isNotEmpty && !r['title'].toString().toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Resources'),
        actions: [
          TextButton.icon(
            onPressed: () => openPage(context, const ResourceFormScreen(), onBack: _load),
            icon: const Icon(Icons.upload),
            label: const Text('Upload'),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBox(hint: 'Search resources...', onChanged: (v) => setState(() => _search = v)),
          CategoryChips(
            options: ['All', ...AppConfig.resourceCategories],
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 4),
          CategoryChips(
            options: ['All', ...AppConfig.departments],
            selected: _department,
            onSelected: (v) => setState(() => _department = v),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load)
                    : list.isEmpty
                        ? const EmptyView(message: 'No resources found', icon: Icons.menu_book)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final r = list[i];
                                return ItemCard(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFFFEBEE),
                                    child: Icon(Icons.picture_as_pdf, color: Colors.red),
                                  ),
                                  title: r['title'],
                                  subtitle: '${r['department']}-${r['semester']} Sem • ${r['category']}',
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => openLink(context, r['file_url']),
                                  ),
                                  onTap: () => openPage(context, ResourceDetailScreen(resource: r), onBack: _load),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
