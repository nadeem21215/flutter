import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/network/http_exception.dart';
import '../../data/services/api_service.dart';
import '../../data/services/notification_service.dart';
import '../student/student_shell.dart';
import '../doctor/doctor_shell.dart';
import '../admin/admin_shell.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _api = ApiService();

  // Student tab
  final _studentCodeCtrl = TextEditingController();
  final _studentPassCtrl = TextEditingController();
  final _studentFormKey  = GlobalKey<FormState>();

  // Doctor tab
  final _doctorUserCtrl  = TextEditingController();
  final _doctorPassCtrl  = TextEditingController();
  final _doctorFormKey   = GlobalKey<FormState>();

  bool   _loading         = false;
  bool   _obscureStudent  = true;
  bool   _obscureDoctor   = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _studentCodeCtrl.dispose(); _studentPassCtrl.dispose();
    _doctorUserCtrl.dispose();  _doctorPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final isStudent = _tabs.index == 0;
    final formKey   = isStudent ? _studentFormKey : _doctorFormKey;
    if (!formKey.currentState!.validate()) return;

    final username = isStudent
        ? _studentCodeCtrl.text.trim()
        : _doctorUserCtrl.text.trim();
    final password = isStudent
        ? _studentPassCtrl.text.trim()
        : _doctorPassCtrl.text.trim();

    setState(() { _loading = true; _error = null; });

    try {
      final user = await _api.login(username: username, password: password);
      if (!mounted) return;

      context.read<UserProvider>().setUser(
        name:          user.name,
        firebaseUid:   user.firebaseUid,
        role:          user.role,
        studentCode:   user.studentCode,
        level:         user.level,
        gpa:           user.gpa,
        creditHours:   user.creditHours,
        warnings:      user.warnings,
        hasRegistered: user.hasRegistered,
      );

      // Register this device for push notifications (students only,
      // fire-and-forget — must never block or fail the login).
      if (user.role == AppConstants.roleStudent) {
        NotificationService().registerToken(user.firebaseUid);
      }

      _navigateByRole(user.role);
    } on HttpException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateByRole(String role) {
    Widget dest;
    switch (role) {
      case AppConstants.roleStudent: dest = const StudentShell();  break;
      case AppConstants.roleDoctor:  dest = const DoctorShell();   break;
      case AppConstants.roleAdmin:   dest = const AdminShell();    break;
      default:
        setState(() => _error = 'Unknown role: $role');
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dest),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(children: [
        const SizedBox(height: 32),

        // Tab bar — Student | Doctor
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TabBar(
            controller: _tabs,
            labelColor:         AppColors.primary,
            unselectedLabelColor: AppColors.textGray,
            labelStyle:   const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            unselectedLabelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, fontFamily: 'Poppins'),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [Tab(text: 'Student'), Tab(text: 'Doctor')],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _LoginForm(
                formKey:     _studentFormKey,
                userLabel:   'Student Code',
                userCtrl:    _studentCodeCtrl,
                passCtrl:    _studentPassCtrl,
                obscure:     _obscureStudent,
                onToggle:    () => setState(() => _obscureStudent = !_obscureStudent),
                onSubmit:    _login,
                loading:     _loading,
                error:       _error,
              ),
              _LoginForm(
                formKey:     _doctorFormKey,
                userLabel:   'User name',
                userCtrl:    _doctorUserCtrl,
                passCtrl:    _doctorPassCtrl,
                obscure:     _obscureDoctor,
                onToggle:    () => setState(() => _obscureDoctor = !_obscureDoctor),
                onSubmit:    _login,
                loading:     _loading,
                error:       _error,
              ),
            ],
          ),
        ),
      ]),
    ),
  );
}

// ─── Reusable Login Form ──────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String               userLabel;
  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final bool                 obscure;
  final VoidCallback         onToggle;
  final VoidCallback         onSubmit;
  final bool                 loading;
  final String?              error;

  const _LoginForm({
    required this.formKey,
    required this.userLabel,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
    required this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Form(
      key: formKey,
      child: Column(children: [
        const SizedBox(height: 16),

        // Avatar placeholder
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
          child: const Icon(Icons.person_rounded, size: 64, color: AppColors.primary),
        ),

        const SizedBox(height: 36),

        // Username field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(userLabel, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins',
          )),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:    userCtrl,
          textDirection: TextDirection.ltr,
          decoration:    const InputDecoration(),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),

        const SizedBox(height: 20),

        // Password field
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Password', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins',
          )),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:  passCtrl,
          obscureText: obscure,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textGray, size: 20),
              onPressed: onToggle,
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),

        // Error
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 40),

        // Sign in button
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Sign in'),
        ),
      ]),
    ),
  );
}
