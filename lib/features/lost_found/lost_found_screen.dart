import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'lost_found_detail_screen.dart';
import 'lost_found_form_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _type = 'lost';
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
      final data = await supabase.from('lost_found_items').select().order('created_at', ascending: false);
      _items = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load items.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    return _items.where((item) {
      if (item['type'] != _type) return false;
      if (_category != 'All' && item['category'] != _category) return false;
      if (_search.isNotEmpty && !item['title'].toString().toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          TextButton.icon(
            onPressed: () => openPage(context, const LostFoundFormScreen(), onBack: _load),
            icon: const Icon(Icons.add),
            label: const Text('Post'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lost', label: Text('Lost')),
                  ButtonSegment(value: 'found', label: Text('Found')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
          ),
          SearchBox(hint: 'Search items...', onChanged: (v) => setState(() => _search = v)),
          CategoryChips(
            options: ['All', ...AppConfig.lostCategories],
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
                        ? const EmptyView(message: 'No items found')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final item = list[i];
                                final recovered = item['status'] == 'recovered';
                                return ItemCard(
                                  leading: NetworkThumb(url: item['image_url'], icon: Icons.inventory_2),
                                  title: '${item['type'] == 'lost' ? 'Lost' : 'Found'}: ${item['title']}',
                                  subtitle: '${item['location']}\n${formatDate(item['item_date'])}',
                                  trailing: recovered
                                      ? const StatusBadge(text: 'Recovered', color: Colors.green)
                                      : const Icon(Icons.chevron_right, color: AppColors.textLight),
                                  onTap: () => openPage(context, LostFoundDetailScreen(item: item), onBack: _load),
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
