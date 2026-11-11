import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

class EventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event;
  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _organizer = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  File? _image;
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _title.text = e['title'];
      _description.text = e['description'] ?? '';
      _location.text = e['location'] ?? '';
      _organizer.text = e['organizer'] ?? '';
      _dateTime = DateTime.parse(e['event_date']).toLocal();
    }
  }

  Future<void> _pickDateTime() async {
    final date = await pickDate(context, initial: _dateTime);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
    if (time == null) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = widget.event?['image_url'];
      if (_image != null) imageUrl = await uploadFile(_image!, 'events');

      final data = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'location': _location.text.trim(),
        'organizer': _organizer.text.trim(),
        'event_date': _dateTime.toUtc().toIso8601String(),
        'image_url': imageUrl,
      };
      if (_isEdit) {
        await supabase.from('events').update(data).eq('id', widget.event!['id']);
      } else {
        data['created_by'] = AppState.uid;
        await supabase.from('events').insert(data);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Event updated' : 'Event created');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Not allowed or something went wrong.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Event' : 'Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerBox(
                file: _image,
                networkUrl: widget.event?['image_url'],
                label: 'Add Event Image',
                onTap: () async {
                  final f = await pickImage();
                  if (f != null) setState(() => _image = f);
                },
              ),
              AppTextField(controller: _title, label: 'Event title', icon: Icons.title,
                  validator: (v) => Validators.required(v, 'Title')),
              AppTextField(controller: _description, label: 'Description', maxLines: 4,
                  validator: (v) => Validators.required(v, 'Description')),
              AppTextField(controller: _location, label: 'Location', icon: Icons.location_on_outlined,
                  validator: (v) => Validators.required(v, 'Location')),
              AppTextField(controller: _organizer, label: 'Organizer', icon: Icons.groups_outlined,
                  validator: (v) => Validators.required(v, 'Organizer')),
              ListTile(
                tileColor: context.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.calendar_today),
                title: Text('Date & time: ${formatDateTime(_dateTime.toIso8601String())}'),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 20),
              AppButton(label: _isEdit ? 'Update' : 'Create', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}