import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Map<String, dynamic> _event;
  bool _registered = false;
  int _count = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadRegistration();
  }

  
  Future<void> _loadRegistration() async {
    try {
      final all = await supabase.from('event_registrations').select('id').eq('event_id', _event['id']);
      final mine = await supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', _event['id'])
          .eq('user_id', AppState.uid)
          .maybeSingle();
      _count = all.length;
      _registered = mine != null;
    } catch (e) {
      if (mounted) showMessage(context, 'Could not load registration.', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleRegistration() async {
    setState(() => _busy = true);
    try {
      if (_registered) {
        await supabase
            .from('event_registrations')
            .delete()
            .eq('event_id', _event['id'])
            .eq('user_id', AppState.uid);
        if (mounted) showMessage(context, 'Registration cancelled');
      } else {
        await supabase.from('event_registrations').insert({
          'event_id': _event['id'],
          'user_id': AppState.uid,
        });
        if (mounted) showMessage(context, 'You joined this event!');
      }
      await _loadRegistration();
    } catch (e) {
      if (mounted) showMessage(context, 'Something went wrong.', isError: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Delete event', 'Do you really want to delete this event?');
    if (!ok) return;
    try {
      await supabase.from('events').delete().eq('id', _event['id']);
      if (!mounted) return;
      showMessage(context, 'Event deleted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not delete.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPast = DateTime.parse(_event['event_date']).isBefore(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (AppState.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(event: _event)));
                final fresh = await supabase.from('events').select().eq('id', _event['id']).maybeSingle();
                if (fresh != null && mounted) setState(() => _event = fresh);
              },
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_event['image_url'] != null && _event['image_url'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_event['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Text(_event['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          InfoRow(icon: Icons.calendar_today, text: formatDateTime(_event['event_date'])),
          InfoRow(icon: Icons.location_on_outlined, text: _event['location'] ?? ''),
          InfoRow(icon: Icons.groups_outlined, text: 'Organizer: ${_event['organizer'] ?? ''}'),
          InfoRow(icon: Icons.person_add_alt, text: '$_count student(s) registered'),
          const Divider(height: 30),
          Text(_event['description'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          if (_loading)
            const LoadingView()
          else if (isPast)
            const Center(child: Text('This event has ended'))
          else
            AppButton(
              label: _registered ? 'Cancel Registration' : 'Join Event',
              outlined: _registered,
              loading: _busy,
              onPressed: _toggleRegistration,
            ),
        ],
      ),
    );
  }
}
