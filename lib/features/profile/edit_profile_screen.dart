import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';


class EditProfileScreen extends StatefulWidget {
  final bool forceComplete;
  const EditProfileScreen({super.key, this.forceComplete = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _phone = TextEditingController();
  String? _department;
  File? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = AppState.profile ?? {};
    _name.text = p['full_name'] ?? '';
    
    final sid = (p['student_id'] ?? '').toString();
    _studentId.text = sid == p['id'] ? '' : sid;
    _phone.text = p['phone'] ?? '';
    final dep = p['department'];
    _department = AppConfig.departments.contains(dep) ? dep : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? avatarUrl = AppState.profile?['avatar_url'];
      if (_image != null) avatarUrl = await uploadFile(_image!, 'avatars');

      
      await supabase.from('profiles').update({
        'full_name': _name.text.trim(),
        'student_id': _studentId.text.trim(),
        'phone': _phone.text.trim(),
        'department': _department,
        'avatar_url': avatarUrl,
      }).eq('id', AppState.uid);

      await AppState.loadProfile();
      if (!mounted) return;
      showMessage(context, 'Profile saved');
      if (widget.forceComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pop(context);
      }
      return;
    } on PostgrestException catch (e) {
      
      final msg = e.code == '23505'
          ? 'This Student ID is already used by another account.'
          : 'Could not save profile.';
      if (mounted) showMessage(context, msg, isError: true);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not save profile.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    AppState.profile = null;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AppState.profile?['avatar_url'] as String?;
    ImageProvider? image;
    if (_image != null) {
      image = FileImage(_image!);
    } else if (avatar != null && avatar.isNotEmpty) {
      image = NetworkImage(avatar);
    }

    return PopScope(
      canPop: !widget.forceComplete,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forceComplete,
          title: Text(widget.forceComplete ? 'Complete Your Profile' : 'Edit Profile'),
          actions: [
            if (widget.forceComplete)
              TextButton(onPressed: _logout, child: const Text('Logout')),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (widget.forceComplete)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Please add your Student ID, phone number and department to continue.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                GestureDetector(
                  onTap: () async {
                    final f = await pickImage();
                    if (f != null) setState(() => _image = f);
                  },
                  child: CircleAvatar(
                    radius: 54,
                    backgroundImage: image,
                    child: image == null ? const Icon(Icons.add_a_photo, size: 36) : null,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Tap to change picture'),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _name,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => Validators.required(v, 'Full name'),
                ),
                AppTextField(
                  controller: _studentId,
                  label: 'Student ID',
                  icon: Icons.badge_outlined,
                  validator: Validators.studentId,
                ),
                AppTextField(
                  controller: _phone,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                AppDropdown(
                  label: 'Department',
                  value: _department,
                  items: AppConfig.departments,
                  onChanged: (v) => setState(() => _department = v),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: widget.forceComplete ? 'Save & Continue' : 'Save',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}