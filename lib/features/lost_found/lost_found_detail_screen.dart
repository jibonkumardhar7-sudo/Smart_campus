import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'lost_found_form_screen.dart';

class LostFoundDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const LostFoundDetailScreen({super.key, required this.item});

  @override
  State<LostFoundDetailScreen> createState() => _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends State<LostFoundDetailScreen> {
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  bool get _isOwner => _item['user_id'] == AppState.uid;
  bool get _canDelete => _isOwner || AppState.isAdmin;

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Delete post', 'Do you really want to delete this post?');
    if (!ok) return;
    try {
      await supabase.from('lost_found_items').delete().eq('id', _item['id']);
      if (!mounted) return;
      showMessage(context, 'Post deleted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not delete.', isError: true);
    }
  }

  Future<void> _markRecovered() async {
    try {
      await supabase.from('lost_found_items').update({'status': 'recovered'}).eq('id', _item['id']);
      setState(() => _item = {..._item, 'status': 'recovered'});
      if (mounted) showMessage(context, 'Marked as recovered');
    } catch (e) {
      if (mounted) showMessage(context, 'Could not update.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recovered = _item['status'] == 'recovered';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => LostFoundFormScreen(item: _item)));
                
                final fresh = await supabase.from('lost_found_items').select().eq('id', _item['id']).maybeSingle();
                if (fresh != null && mounted) setState(() => _item = fresh);
              },
            ),
          if (_canDelete) IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_item['image_url'] != null && _item['image_url'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_item['image_url'], height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusBadge(
                text: _item['type'] == 'lost' ? 'LOST' : 'FOUND',
                color: _item['type'] == 'lost' ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              if (recovered) const StatusBadge(text: 'RECOVERED', color: Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          Text(_item['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_item['description'] ?? ''),
          const SizedBox(height: 14),
          InfoRow(icon: Icons.category_outlined, text: _item['category'] ?? ''),
          InfoRow(icon: Icons.location_on_outlined, text: _item['location'] ?? ''),
          InfoRow(icon: Icons.calendar_today, text: formatDate(_item['item_date'])),
          InfoRow(icon: Icons.phone, text: _item['contact'] ?? ''),
          const SizedBox(height: 20),
          if ((_item['contact'] ?? '').toString().isNotEmpty)
            AppButton(label: 'Call Contact', icon: Icons.call, onPressed: () => callNumber(context, _item['contact'])),
          const SizedBox(height: 10),
          if (_isOwner && !recovered)
            AppButton(label: 'Mark as Recovered / Claimed', outlined: true, onPressed: _markRecovered),
        ],
      ),
    );
  }
}
