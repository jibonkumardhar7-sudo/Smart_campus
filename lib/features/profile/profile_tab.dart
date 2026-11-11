import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/theme_controller.dart';
import '../../core/validators.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_posts_screen.dart';
import 'notifications_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _refresh() async {
    await AppState.loadProfile();
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'Logout', 'Do you want to logout?');
    if (!ok) return;
    await supabase.auth.signOut();
    AppState.profile = null;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (newPassword == null) return;
    final error = Validators.password(newPassword);
    if (error != null) {
      if (mounted) showMessage(context, error, isError: true);
      return;
    }
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      if (mounted) showMessage(context, 'Password changed');
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
  }

  Future<void> _chooseTheme() async {
    final current = ThemeController.mode.value;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          _themeOption(ctx, ThemeMode.system, 'System default', Icons.phone_android, current),
          _themeOption(ctx, ThemeMode.light, 'Light', Icons.light_mode, current),
          _themeOption(ctx, ThemeMode.dark, 'Dark', Icons.dark_mode, current),
        ],
      ),
    );
    if (selected != null) {
      await ThemeController.set(selected);
    }
  }

  Widget _themeOption(BuildContext ctx, ThemeMode mode, String label, IconData icon, ThemeMode current) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, mode),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (current == mode) const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppState.profile ?? {};
    final avatar = p['avatar_url'] as String?;
    final department = AppConfig.departmentName(p['department']?.toString());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('My Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
            child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person, size: 50) : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(p['full_name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        if (AppState.isAdmin)
          const Center(child: Padding(padding: EdgeInsets.only(top: 4), child: Chip(label: Text('Admin')))),
        const SizedBox(height: 16),
        Card(
          color: context.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _info(Icons.account_balance_outlined, 'University', AppConfig.universityName),
                _info(Icons.badge_outlined, 'Student ID', p['student_id']),
                _info(Icons.school_outlined, 'Department', department.isEmpty ? null : department),
                _info(Icons.email_outlined, 'Email', p['email']),
                _info(Icons.phone_outlined, 'Phone', p['phone']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _menu(Icons.edit_outlined, 'Edit Profile', () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          _refresh();
        }),
        _menu(Icons.article_outlined, 'My Posts, Events & Uploads', () => openPage(context, const MyPostsScreen())),
        _menu(Icons.notifications_outlined, 'Notifications', () => openPage(context, const NotificationsScreen())),
        _menu(Icons.brightness_6_outlined, 'Appearance (Light / Dark)', _chooseTheme),
        _menu(Icons.settings_outlined, 'Account Settings (Change Password)', _changePassword),
        _menu(Icons.logout, 'Logout', _logout, color: Colors.red),
      ],
    );
  }

  Widget _info(IconData icon, String label, dynamic value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
      subtitle: Text((value ?? '-').toString(), style: const TextStyle(fontSize: 15)),
    );
  }

  Widget _menu(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Card(
      color: context.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}