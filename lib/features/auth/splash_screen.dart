import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import 'auth_router.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    Widget next = const LoginScreen();
    if (supabase.auth.currentSession != null) {
      try {
        await AppState.loadProfile();
        next = homeOrCompleteProfile();
      } catch (e) {
        next = const LoginScreen();
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 2))];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/campus.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(color: AppColors.dark),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.dark.withOpacity(0.60),
                  AppColors.dark.withOpacity(0.35),
                  AppColors.primary.withOpacity(0.85),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConfig.universityName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 5,
                  shadows: shadow,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Smart Campus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  shadows: shadow,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'All-in-One Student Platform',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1,
                  shadows: shadow,
                ),
              ),
              const SizedBox(height: 44),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}