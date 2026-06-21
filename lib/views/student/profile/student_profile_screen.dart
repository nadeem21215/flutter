import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/user_images.dart';
import '../../../core/providers/user_provider.dart';
import '../courses/student_courses_screen.dart';
import '../../widgets/shared_widgets.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../shared/about_app_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to Log out?',
      highlightWord: 'Log out',
    );
    if (confirmed == true && context.mounted) {
      context.read<UserProvider>().clearUser();
      Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final imageBytes = UserImages.getImageBytes(user.firebaseUid);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.cardGray,
            backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
            child: imageBytes == null ? const Icon(Icons.person_rounded, size: 64, color: AppColors.textGray) : null,
          ),
          const SizedBox(height: 16),
          Text(user.name ?? 'Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Poppins')),
          if (user.studentCode != null) ...[
            const SizedBox(height: 4),
            Text(user.studentCode!, style: const TextStyle(fontSize: 15, color: AppColors.textGray, fontFamily: 'Poppins')),
          ],
          if (user.level != null) ...[
            const SizedBox(height: 4),
            Text(user.level!, style: const TextStyle(fontSize: 14, color: AppColors.textBlue, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ],
          const SizedBox(height: 28),
          // BUG FIX #14: Profile tile onTap handlers were empty — tapping them
          // did nothing. "My Courses" now navigates to StudentCoursesScreen.
          _ProfileTile(label: 'My Courses', onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const StudentCoursesScreen()))),
          const SizedBox(height: 12),
          _ProfileTile(label: 'About App', onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AboutAppScreen()))),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout', style: TextStyle(color: AppColors.textRed, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ProfileTile({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: AppColors.cardGray, borderRadius: BorderRadius.circular(30)),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins')),
    ),
  );
}
