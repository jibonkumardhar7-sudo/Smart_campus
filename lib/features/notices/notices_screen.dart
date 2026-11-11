import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'notice_detail_screen.dart';
import 'notice_form_screen.dart';

Color noticeColor(String category) {
  switch (category) {
    case 'Academic':
      return Colors.red;
    case 'Exam':
      return Colors.orange;
    case 'Event':
      return Colors.green;
    default:
      return Colors.blue;
  }
}

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';
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
      final data = await supabase.from('notices').select().order('created_at', ascending: false);
      _notices = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load notices.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    return _notices.where((n) {
      if (_category != 'All' && n['category'] != _category) return false;
      if (_search.isNotEmpty && !n['title'].toString().toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        actions: [
          // Only admins see the Add button (the database also blocks students)
          if (AppState.isAdmin)
            TextButton.icon(
              onPressed: () => openPage(context, const NoticeFormScreen(), onBack: _load),
              icon: const Icon(Icons.add),
              label: const Text('Add Notice'),
            ),
        ],
      ),
      body: Column(
        children: [
          SearchBox(hint: 'Search notice...', onChanged: (v) => setState(() => _search = v)),
          CategoryChips(
            options: ['All', ...AppConfig.noticeCategories],
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load)
                    : list.isEmpty
                        ? const EmptyView(message: 'No notices found')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final n = list[i];
                                return ItemCard(
                                  leading: const CircleAvatar(child: Icon(Icons.campaign)),
                                  title: n['title'],
                                  subtitle: formatDate(n['created_at']),
                                  trailing: StatusBadge(text: n['category'], color: noticeColor(n['category'])),
                                  onTap: () => openPage(context, NoticeDetailScreen(notice: n), onBack: _load),
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
