import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';

/// Keeps the logged-in user's profile (name, role...) in memory.
class AppState {
  static Map<String, dynamic>? profile;

  static bool get isAdmin => profile != null && profile!['role'] == 'admin';
  static String get uid => supabase.auth.currentUser!.id;

  static bool get profileIncomplete {
    final p = profile;
    if (p == null) return false;
    bool empty(dynamic v) => v == null || v.toString().trim().isEmpty;
    return p['student_id'] == p['id'] ||
        empty(p['student_id']) ||
        empty(p['phone']) ||
        empty(p['department']);
  }

  static Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      profile = null;
      return;
    }
    profile = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
  }
}

void showMessage(BuildContext context, String text, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
      ],
    ),
  );
  return result ?? false;
}

String formatDate(dynamic value) {
  if (value == null) return '';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return DateFormat('d MMM yyyy').format(date.toLocal());
}

String formatDateTime(dynamic value) {
  if (value == null) return '';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return DateFormat('d MMM yyyy, h:mm a').format(date.toLocal());
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial}) {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
}

Future<File?> pickImage() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
  if (picked == null) return null;
  return File(picked.path);
}

/// Uploads a file to Supabase Storage and returns its public URL.
/// Files are saved inside a folder named with the user's id (needed by the storage policy).
Future<String> uploadFile(File file, String folder) async {
  final name = file.path.split('/').last.replaceAll(' ', '_');
  final path = '${AppState.uid}/$folder/${DateTime.now().millisecondsSinceEpoch}_$name';
  await supabase.storage.from(AppConfig.storageBucket).upload(path, file);
  return supabase.storage.from(AppConfig.storageBucket).getPublicUrl(path);
}

Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showMessage(context, 'Could not open the link', isError: true);
}

Future<void> callNumber(BuildContext context, String phone) => openLink(context, 'tel:$phone');

/// Opens a new screen. When we come back, [onBack] runs (used to refresh lists).
void openPage(BuildContext context, Widget page, {VoidCallback? onBack}) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
    if (onBack != null) onBack();
  });
}