import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'marketplace_form_screen.dart';

class MarketplaceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const MarketplaceDetailScreen({super.key, required this.item});

  @override
  State<MarketplaceDetailScreen> createState() => _MarketplaceDetailScreenState();
}

class _MarketplaceDetailScreenState extends State<MarketplaceDetailScreen> {
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  bool get _isOwner => _item['user_id'] == AppState.uid;

  Future<void> _reload() async {
    final fresh = await supabase
        .from('marketplace_items')
        .select('*, profiles(full_name, phone, email)')
        .eq('id', _item['id'])
        .maybeSingle();
    if (fresh != null && mounted) setState(() => _item = fresh);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Delete listing', 'Do you really want to delete this listing?');
    if (!ok) return;
    try {
      await supabase.from('marketplace_items').delete().eq('id', _item['id']);
      if (!mounted) return;
      showMessage(context, 'Listing deleted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not delete.', isError: true);
    }
  }

  Future<void> _markSold() async {
    try {
      await supabase.from('marketplace_items').update({'status': 'sold'}).eq('id', _item['id']);
      await _reload();
      if (mounted) showMessage(context, 'Marked as sold');
    } catch (e) {
      if (mounted) showMessage(context, 'Could not update.', isError: true);
    }
  }

  // Report an inappropriate listing: it is saved as a complaint for the admins.
  Future<void> _report() async {
    final ok = await confirmDialog(context, 'Report listing', 'Report this listing as inappropriate?');
    if (!ok) return;
    try {
      await supabase.from('complaints').insert({
        'user_id': AppState.uid,
        'type': 'complaint',
        'category': 'Other',
        'description': 'Reported marketplace listing: "${_item['title']}" (id: ${_item['id']})',
      });
      if (mounted) showMessage(context, 'Thanks! Admins will review this listing.');
    } catch (e) {
      if (mounted) showMessage(context, 'Could not send report.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = _item['profiles'] as Map<String, dynamic>?;
    final sold = _item['status'] == 'sold';
    final phone = seller?['phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceFormScreen(item: _item)));
                await _reload();
              },
            ),
          // Owner can delete; admin can delete inappropriate listings
          if (_isOwner || AppState.isAdmin) IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
          if (!_isOwner) IconButton(icon: const Icon(Icons.flag_outlined), onPressed: _report),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_item['image_url'] != null && _item['image_url'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_item['image_url'], height: 240, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(_item['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (sold) const StatusBadge(text: 'SOLD', color: Colors.red),
            ],
          ),
          Text('৳ ${_item['price']}',
              style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_item['description'] ?? ''),
          const SizedBox(height: 14),
          InfoRow(icon: Icons.category_outlined, text: _item['category'] ?? ''),
          InfoRow(icon: Icons.verified_outlined, text: _item['condition'] ?? ''),
          InfoRow(icon: Icons.calendar_today, text: formatDate(_item['created_at'])),
          const Divider(height: 30),
          const Text('Seller', style: TextStyle(fontWeight: FontWeight.bold)),
          InfoRow(icon: Icons.person_outline, text: seller?['full_name'] ?? 'Unknown'),
          InfoRow(icon: Icons.phone_outlined, text: phone),
          InfoRow(icon: Icons.email_outlined, text: seller?['email'] ?? ''),
          const SizedBox(height: 20),
          if (!_isOwner && phone.isNotEmpty)
            AppButton(label: 'Contact Seller', icon: Icons.call, onPressed: () => callNumber(context, phone)),
          if (_isOwner && !sold) AppButton(label: 'Mark as Sold', outlined: true, onPressed: _markSold),
        ],
      ),
    );
  }
}
