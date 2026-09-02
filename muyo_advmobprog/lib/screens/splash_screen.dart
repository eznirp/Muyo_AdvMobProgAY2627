import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final loggedIn = await _userService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final user = await _userService.getUserData();
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home', arguments: user);
        return;
      }
    }
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/nubdexchange_logo.png',
          width: 170,
          errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag, size: 72),
        ),
      ),
    );
  }
}
