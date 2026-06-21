import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/user_images.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _version = '2.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About App',
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── App identity ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.primary, size: 42),
              ),
              const SizedBox(height: 14),
              const Text('Smart Institute App',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Version $_version',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ),
              const SizedBox(height: 12),
              const Text(
                'A complete academic management system for the Higher Institute of Computer Science & Information Systems — connecting students, instructors, and administration in one smart platform.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.6,
                    fontFamily: 'Poppins'),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Features ──
          const _SectionTitle(icon: Icons.star_rounded, title: 'Main Features'),
          const _FeatureGroup(
            color: AppColors.cardBlue,
            title: 'For Students',
            icon: Icons.person_rounded,
            features: [
              'Smart course registration with GPA-based rules',
              'Weekly schedule of registered courses',
              'Assignments: view, download & submit solutions',
              'AI academic assistant chat (Gemini-powered)',
              'Push notifications for new assignments',
              'Detailed course descriptions & prerequisites',
            ],
          ),
          const SizedBox(height: 10),
          const _FeatureGroup(
            color: AppColors.cardGray,
            title: 'For Doctors',
            icon: Icons.co_present_rounded,
            features: [
              'Teaching schedule with enrolled student counts',
              'Create & send assignments to course students',
              'Review and download student submissions',
              'Edit course descriptions',
            ],
          ),
          const SizedBox(height: 10),
          const _FeatureGroup(
            color: AppColors.cardBlue,
            title: 'For Admins',
            icon: Icons.admin_panel_settings_rounded,
            features: [
              'Manage students, courses & academic records',
              'Monitor registrations and warnings',
              'Full academic data control',
            ],
          ),

          const SizedBox(height: 24),

          // ── Technology Stack ──
          const _SectionTitle(
              icon: Icons.layers_rounded, title: 'Technology Stack'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TechChip(label: 'Flutter', icon: Icons.flutter_dash),
              _TechChip(label: 'FastAPI', icon: Icons.bolt_rounded),
              _TechChip(label: 'SQLite', icon: Icons.storage_rounded),
              _TechChip(
                  label: 'Firebase FCM',
                  icon: Icons.notifications_active_rounded),
              _TechChip(
                  label: 'Google Gemini AI', icon: Icons.smart_toy_rounded),
              _TechChip(label: 'Railway', icon: Icons.cloud_rounded),
            ],
          ),

          const SizedBox(height: 24),

          // ── Team ──
          const _SectionTitle(
              icon: Icons.groups_rounded, title: 'Development Team'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: const [
                  _TeamMember(uid: '220423', name: 'Yasser'),
                  _TeamMember(uid: '221798', name: 'Osama'),
                  _TeamMember(uid: '223012', name: 'Mohanad'),
                  _TeamMember(uid: '222072', name: 'Moaz'),
                  _TeamMember(uid: '221730', name: 'Nadeem'),
                  _TeamMember(uid: '221037', name: 'Basmalah'),
                  _TeamMember(uid: '221737', name: 'Manar'),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Text('Under the supervision of Dr. Omaima Goher',
                  style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins')),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Contact ──
          const _SectionTitle(icon: Icons.mail_rounded, title: 'Contact Us'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(children: [
              _ContactRow(
                  icon: Icons.email_rounded,
                  text: 'support@smartinstitute.edu.eg'),
              SizedBox(height: 10),
              _ContactRow(icon: Icons.phone_rounded, text: '+201556497369'),
              SizedBox(height: 10),
              _ContactRow(
                  icon: Icons.location_on_rounded,
                  text: 'Higher Institute of Computer Science & IS, Egypt'),
            ]),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text('© 2026 Smart Institute — Graduation Project',
                style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11,
                    fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins')),
        ]),
      );
}

// ── Feature group card ─────────────────────────────────────────────────────────
class _FeatureGroup extends StatelessWidget {
  final Color color;
  final String title;
  final IconData icon;
  final List<String> features;
  const _FeatureGroup(
      {required this.color,
      required this.title,
      required this.icon,
      required this.features});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 10),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textDark,
                                fontFamily: 'Poppins')),
                      ),
                    ]),
              )),
        ]),
      );
}

// ── Tech chip ──────────────────────────────────────────────────────────────────
class _TechChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TechChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentMedium.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins')),
        ]),
      );
}

// ── Team member avatar ─────────────────────────────────────────────────────────
class _TeamMember extends StatelessWidget {
  final String uid;
  final String name;
  const _TeamMember({required this.uid, required this.name});

  @override
  Widget build(BuildContext context) {
    final bytes = UserImages.getImageBytes(uid);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.background,
        backgroundImage: bytes != null ? MemoryImage(bytes) : null,
        child: bytes == null
            ? const Icon(Icons.person_rounded, color: AppColors.textGray)
            : null,
      ),
      const SizedBox(height: 4),
      Text(name,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontFamily: 'Poppins')),
    ]);
  }
}

// ── Contact row ────────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins')),
        ),
      ]);
}
