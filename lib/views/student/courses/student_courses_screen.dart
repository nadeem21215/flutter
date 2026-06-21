import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _api = ApiService();
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  // Fix #2 – track the last registrationVersion we loaded for; when it
  // changes (a new registration happened) we automatically reload.
  int _loadedVersion = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = context.read<UserProvider>().registrationVersion;
    if (_loadedVersion != version) {
      _loadedVersion = version;
      _load();
    }
  }

  Future<void> _load() async {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.getStudentRegisteredCourses(firebaseUid: uid);
      if (!mounted) return;
      setState(() {
        _courses = res;
        _loading = false;
      });
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fix #2 – watch the provider so didChangeDependencies fires when
    // registrationVersion increments after a successful registration.
    context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Courses'),
        // This screen is used both as a bottom-nav tab (no back arrow needed)
        // and as a pushed route from the profile screen (back arrow needed).
        // Showing the arrow only when there's actually something to pop to
        // avoids a dead button on the tab and keeps it working everywhere else.
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
              ? AppError(
                  message: _error!,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _courses.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No enrolled courses yet.',
                                style: TextStyle(
                                  color: AppColors.textGray,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _courses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => CourseTileBlue(
                            name: _courses[i].name,
                            code: _courses[i].code,
                            creditHours: _courses[i].creditHours,
                          ),
                        ),
                ),
    );
  }
}
