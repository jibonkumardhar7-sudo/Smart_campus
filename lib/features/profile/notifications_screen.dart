import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
          .from('notifications')
          .select()
          .eq('user_id', AppState.uid)
          .order('created_at', ascending: false)
          .limit(50);
      _list = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load notifications.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('user_id', AppState.uid);
      _load();
    } catch (e) {
      if (mounted) showMessage(context, 'Could not update.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: _markAllRead, child: const Text('Mark all read'))],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load)
              : _list.isEmpty
                  ? const EmptyView(message: 'No notifications', icon: Icons.notifications_none)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final n = _list[i];
                          final unread = n['is_read'] == false;
                          return ItemCard(
                            leading: CircleAvatar(
                              child: Icon(unread ? Icons.notifications_active : Icons.notifications_none),
                            ),
                            title: n['title'],
                            subtitle: '${n['message'] ?? ''}\n${formatDateTime(n['created_at'])}',
                            trailing: unread ? const Icon(Icons.circle, size: 10, color: Colors.red) : const SizedBox(),
                          );
                        },
                      ),
                    ),
    );
  }
}
