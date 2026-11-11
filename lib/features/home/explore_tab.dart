import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import '../events/event_detail_screen.dart';
import '../lost_found/lost_found_detail_screen.dart';
import '../marketplace/marketplace_detail_screen.dart';
import '../notices/notice_detail_screen.dart';
import '../study_resources/resource_detail_screen.dart';

/// Search across all campus content.
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
      _results.clear();
    });
    try {
      final notices = await supabase.from('notices').select().ilike('title', '%$q%').limit(5);
      final events = await supabase.from('events').select().ilike('title', '%$q%').limit(5);
      final lost = await supabase.from('lost_found_items').select().ilike('title', '%$q%').limit(5);
      final resources = await supabase.from('study_resources').select().ilike('title', '%$q%').limit(5);
      final items = await supabase
          .from('marketplace_items')
          .select('*, profiles(full_name, phone, email)')
          .ilike('title', '%$q%')
          .limit(5);

      for (final n in notices) {
        _results.add({'kind': 'Notice', 'icon': Icons.campaign, 'title': n['title'], 'data': n});
      }
      for (final e in events) {
        _results.add({'kind': 'Event', 'icon': Icons.event, 'title': e['title'], 'data': e});
      }
      for (final l in lost) {
        _results.add({'kind': 'Lost & Found', 'icon': Icons.inventory_2, 'title': l['title'], 'data': l});
      }
      for (final r in resources) {
        _results.add({'kind': 'Resource', 'icon': Icons.menu_book, 'title': r['title'], 'data': r});
      }
      for (final i in items) {
        _results.add({'kind': 'Marketplace', 'icon': Icons.shopping_cart, 'title': i['title'], 'data': i});
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Search failed. Try again.', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _open(Map<String, dynamic> result) {
    final data = Map<String, dynamic>.from(result['data']);
    Widget page;
    switch (result['kind']) {
      case 'Notice':
        page = NoticeDetailScreen(notice: data);
        break;
      case 'Event':
        page = EventDetailScreen(event: data);
        break;
      case 'Lost & Found':
        page = LostFoundDetailScreen(item: data);
        break;
      case 'Resource':
        page = ResourceDetailScreen(resource: data);
        break;
      default:
        page = MarketplaceDetailScreen(item: data);
    }
    openPage(context, page);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('Explore', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Search notices, events, items, resources...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _search(_controller.text)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : !_searched
                  ? const EmptyView(message: 'Search across all campus content', icon: Icons.search)
                  : _results.isEmpty
                      ? const EmptyView(message: 'Nothing found', icon: Icons.search_off)
                      : ListView(
                          children: _results.map((r) {
                            return ItemCard(
                              leading: CircleAvatar(child: Icon(r['icon'])),
                              title: r['title'],
                              subtitle: r['kind'],
                              onTap: () => _open(r),
                            );
                          }).toList(),
                        ),
        ),
      ],
    );
  }
}
