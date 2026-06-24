import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/http_exception.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../shared/about_app_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});
  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _api = ApiService();
  bool   _uploading = false;
  // Cache-buster so the image reloads after upload
  int    _imageVersion = 0;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final uid = context.read<UserProvider>().firebaseUid ?? '';
    setState(() => _uploading = true);
    try {
      await _api.uploadProfilePicture(
        firebaseUid: uid,
        filename:    file.name,
        fileBytes:   file.bytes!,
      );
      if (!mounted) return;
      setState(() => _imageVersion++);
      showSuccess(context, 'Profile picture updated!');
    } on HttpException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showError(context, 'Upload failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final uid  = user.firebaseUid ?? '';
    final pictureUrl = uid.isNotEmpty
        ? '${_api.getProfilePictureUrl(uid)}?v=$_imageVersion'
        : null;

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
          // ── Avatar with edit button ──────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _NetworkAvatar(url: pictureUrl, radius: 70),
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name ?? 'Doctor',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          const Text('Doctor',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 28),
          _Tile(
            label: 'About App',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AboutAppScreen())),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout',
                style: TextStyle(
                    color: AppColors.textRed,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }
}

// ── Shared network avatar widget ─────────────────────────────────────────────
class _NetworkAvatar extends StatelessWidget {
  final String? url;
  final double  radius;
  const _NetworkAvatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cardGray,
      child: Icon(Icons.person_rounded,
          size: radius * 0.9, color: AppColors.textGray),
    );

    if (url == null) return placeholder;

    return ClipOval(
      child: SizedBox(
        width:  radius * 2,
        height: radius * 2,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : placeholder,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

/// Exported so AdminInstructorDetailScreen can reuse it.
class DoctorNetworkAvatar extends StatelessWidget {
  final String? url;
  final double  radius;
  const DoctorNetworkAvatar({super.key, required this.url, required this.radius});

  @override
  Widget build(BuildContext context) => _NetworkAvatar(url: url, radius: radius);
}

class _Tile extends StatelessWidget {
  final String   label;
  final VoidCallback onTap;
  const _Tile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: AppColors.cardGray,
          borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: 'Poppins')),
    ),
  );
}
