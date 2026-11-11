import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _department;
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showMessage(context, 'Please agree to the Terms & Conditions', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'phone': _phoneController.text.trim(),
          'department': _department,
        },
      );
      await supabase.auth.signOut();
      if (!mounted) return;
      showMessage(context, 'Registration successful! Please login.');
      Navigator.pop(context);
    } on AuthException catch (e) {
      var message = e.message;
      if (message.contains('Database error')) {
        message = 'This Student ID is already registered.';
      }
      if (mounted) showMessage(context, message, isError: true);
    } catch (e) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text('Join ${AppConfig.universityName}'),
              const SizedBox(height: 20),
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              AppTextField(
                controller: _studentIdController,
                label: 'Student ID',
                icon: Icons.badge_outlined,
                validator: Validators.studentId,
              ),
              AppTextField(
                controller: _emailController,
                label: 'University Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              AppTextField(
                controller: _phoneController,
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
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: true,
                validator: Validators.password,
              ),
              AppTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                obscure: true,
                validator: (v) => Validators.confirmPassword(v, _passwordController.text),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: const Text('I agree to the Terms & Conditions'),
              ),
              const SizedBox(height: 8),
              AppButton(label: 'Register', loading: _loading, onPressed: _register),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Login')),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}