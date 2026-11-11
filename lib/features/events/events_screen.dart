import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;
  bool _showUpcoming = true;

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
      final data = await supabase.from('events').select().order('event_date', ascending: true);
      _events = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Could not load events.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _events.where((e) {
      final date = DateTime.parse(e['event_date']).toLocal();
      return _showUpcoming ? date.isAfter(now) : date.isBefore(now);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          if (AppState.isAdmin)
            TextButton.icon(
              onPressed: () => openPage(context, const EventFormScreen(), onBack: _load),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Upcoming')),
                  ButtonSegment(value: false, label: Text('Past')),
                ],
                selected: {_showUpcoming},
                onSelectionChanged: (s) => setState(() => _showUpcoming = s.first),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? EmptyView(message: _error!, icon: Icons.error_outline, onRetry: _load)
                    : list.isEmpty
                        ? const EmptyView(message: 'No events here', icon: Icons.event_busy)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final e = list[i];
                                return ItemCard(
                                  leading: NetworkThumb(url: e['image_url'], size: 64, icon: Icons.event),
                                  title: e['title'],
                                  subtitle: '${e['organizer'] ?? ''}\n${formatDateTime(e['event_date'])}',
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                                  onTap: () => openPage(context, EventDetailScreen(event: e), onBack: _load),
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
