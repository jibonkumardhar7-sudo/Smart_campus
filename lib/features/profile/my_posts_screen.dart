import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import '../events/event_detail_screen.dart';
import '../lost_found/lost_found_detail_screen.dart';
import '../marketplace/marketplace_detail_screen.dart';
import '../study_resources/resource_detail_screen.dart';

/// Shows everything the student created: lost & found posts, marketplace listings,
/// uploaded resources and registered events.
class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Posts'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Lost & Found'),
              Tab(text: 'Marketplace'),
              Tab(text: 'Resources'),
              Tab(text: 'My Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyList(
              table: 'lost_found_items',
              select: '*',
              title: (m) => '${m['type'] == 'lost' ? 'Lost' : 'Found'}: ${m['title']}',
              subtitle: (m) => '${m['location']} • ${formatDate(m['item_date'])}',
              imageKey: 'image_url',
              page: (m) => LostFoundDetailScreen(item: m),
            ),
            _MyList(
              table: 'marketplace_items',
              select: '*, profiles(full_name, phone, email)',
              title: (m) => m['title'],
              subtitle: (m) => '৳ ${m['price']} • ${m['status']}',
              imageKey: 'image_url',
              page: (m) => MarketplaceDetailScreen(item: m),
            ),
            _MyList(
              table: 'study_resources',
              select: '*',
              title: (m) => m['title'],
              subtitle: (m) => '${m['department']}-${m['semester']} Sem • ${m['category']}',
              page: (m) => ResourceDetailScreen(resource: m),
            ),
            // Registered events: we read event_registrations and show the joined event
            _MyList(
              table: 'event_registrations',
              select: '*, events(*)',
              title: (m) => m['events']['title'],
              subtitle: (m) => formatDateTime(m['events']['event_date']),
              imageKey: null,
              page: (m) => EventDetailScreen(event: Map<String, dynamic>.from(m['events'])),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyList extends StatefulWidget {
  final String table;
  final String select;
  final String Function(Map<String, dynamic>) title;
  final String Function(Map<String, dynamic>) subtitle;
  final String? imageKey;
  final Widget Function(Map<String, dynamic>) page;

  const _MyList({
    required this.table,
    required this.select,
    required this.title,
    required this.subtitle,
    required this.page,
    this.imageKey,
  });

  @override
  State<_MyList> createState() => _MyListState();
}

class _MyListState extends State<_MyList> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
          .from(widget.table)
          .select(widget.select)
          .eq('user_id', AppState.uid)
          .order('created_at', ascending: false);
      _list = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load your data.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingView();
    if (_error != null) return EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load);
    if (_list.isEmpty) return const EmptyView(message: 'Nothing here yet');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, i) {
          final m = _list[i];
          return ItemCard(
            leading: NetworkThumb(
              url: widget.imageKey == null ? null : m[widget.imageKey],
              icon: Icons.article_outlined,
            ),
            title: widget.title(m),
            subtitle: widget.subtitle(m),
            onTap: () => openPage(context, widget.page(m), onBack: _load),
          );
        },
      ),
    );
  }
}
