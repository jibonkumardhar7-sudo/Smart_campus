import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'notice_form_screen.dart';
import 'notices_screen.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Map<String, dynamic> _notice;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Delete notice', 'Do you really want to delete this notice?');
    if (!ok) return;
    try {
      await supabase.from('notices').delete().eq('id', _notice['id']);
      if (!mounted) return;
      showMessage(context, 'Notice deleted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not delete.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice'),
        actions: [
          if (AppState.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeFormScreen(notice: _notice)));
                final fresh = await supabase.from('notices').select().eq('id', _notice['id']).maybeSingle();
                if (fresh != null && mounted) setState(() => _notice = fresh);
              },
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(text: _notice['category'], color: noticeColor(_notice['category'])),
          ),
          const SizedBox(height: 12),
          Text(_notice['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          InfoRow(icon: Icons.calendar_today, text: formatDate(_notice['created_at'])),
          const Divider(height: 30),
          Text(_notice['body'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
