import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../shared/about_app_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to Log out?',
      highlightWord: 'Log out',
    );
    if (ok == true && context.mounted) {
      context.read<UserProvider>().clearUser();
      Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Profile'),
      
      automaticallyImplyLeading: false,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(children: [
        const SizedBox(height: 16),
        const CircleAvatar(
          radius: 70,
          backgroundColor: AppColors.cardGray,
          child: Icon(Icons.person_rounded, size: 70, color: AppColors.textGray),
        ),
        const SizedBox(height: 16),
        const Text('Admin', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.textDark, fontFamily: 'Poppins')),
        const SizedBox(height: 28),
        _Tile(label: 'About App', onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AboutAppScreen()))),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _logout(context),
          child: const Text('Log out', style: TextStyle(
              color: AppColors.textRed, fontSize: 17,
              fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ),
      ]),
    ),
  );
}

class _Tile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: AppColors.cardGray, borderRadius: BorderRadius.circular(30)),
      child: Text(label, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: AppColors.textDark, fontFamily: 'Poppins')),
    ),
  );
}
