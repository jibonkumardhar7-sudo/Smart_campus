import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'marketplace_detail_screen.dart';
import 'marketplace_form_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> _items = [];
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
      // "profiles(...)" also gets the seller's information
      final data = await supabase
          .from('marketplace_items')
          .select('*, profiles(full_name, phone, email)')
          .order('created_at', ascending: false);
      _items = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load items.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    return _items.where((i) {
      if (_category != 'All' && i['category'] != _category) return false;
      if (_search.isNotEmpty && !i['title'].toString().toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          TextButton.icon(
            onPressed: () => openPage(context, const MarketplaceFormScreen(), onBack: _load),
            icon: const Icon(Icons.add),
            label: const Text('Post Item'),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBox(hint: 'Search products...', onChanged: (v) => setState(() => _search = v)),
          CategoryChips(
            options: ['All', ...AppConfig.marketCategories],
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
                        ? const EmptyView(message: 'No items found', icon: Icons.shopping_bag_outlined)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final item = list[i];
                                final sold = item['status'] == 'sold';
                                return ItemCard(
                                  leading: NetworkThumb(url: item['image_url'], size: 64, icon: Icons.shopping_bag),
                                  title: item['title'],
                                  subtitle: '৳ ${item['price']}\n${item['condition'] ?? ''} • ${item['category']}',
                                  trailing: sold
                                      ? const StatusBadge(text: 'SOLD', color: Colors.red)
                                      : const Icon(Icons.chevron_right),
                                  onTap: () => openPage(context, MarketplaceDetailScreen(item: item), onBack: _load),
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
