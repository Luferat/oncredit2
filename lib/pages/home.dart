// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import '../services/startup_service.dart';
import '../services/biometric_service.dart';
import '../templates/apptitle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupService.run(context);
    });
  }

  Future<void> _loadBiometric() async {
    final enabled = await BiometricService.isEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              const AppTitle(large: true),
              if (_biometricEnabled) ...[
                const SizedBox(height: 24),
                const Icon(Icons.fingerprint, color: Colors.white70, size: 56),
              ],
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}