import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

class CompletedCoursesScreen extends StatefulWidget {
  const CompletedCoursesScreen({super.key});

  @override
  State<CompletedCoursesScreen> createState() => _CompletedCoursesScreenState();
}

class _CompletedCoursesScreenState extends State<CompletedCoursesScreen> {
  final _api = ApiService();
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.getCompletedCourses(firebaseUid: uid);
      setState(() { _courses = res; _loading = false; });
    } on HttpException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Completed Courses'),
      // This screen is also used as a bottom-nav tab; only show the back
      // arrow when there's actually a previous route to pop to.
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
            ? AppError(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: _courses.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No completed courses yet.',
                            style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins'))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        // [FIX #6] Show grade for each course
                        itemBuilder: (_, i) {
                          final c = _courses[i];
                          return _HistoryCourseTile(course: c);
                        },
                      ),
              ),
  );
}

/// Tile that shows course info + grade + pass/fail badge
class _HistoryCourseTile extends StatelessWidget {
  final CourseModel course;
  const _HistoryCourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final passed = course.isPassed;
    final gradeText = (course.grade != null && course.grade!.isNotEmpty)
        ? course.grade!
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: passed
            ? AppColors.cardGray
            : AppColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: passed
            ? null
            : Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
              color: AppColors.textDark, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Row(children: [
            Text(course.code, style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(width: 12),
            Text('${course.creditHours} hrs', style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontFamily: 'Poppins')),
          ]),
        ])),
        // Grade badge
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: passed ? AppColors.primary.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(gradeText, style: TextStyle(
                color: passed ? AppColors.primary : AppColors.error,
                fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 4),
          Text(passed ? 'Passed' : 'Failed',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: passed ? AppColors.primary : AppColors.error, fontFamily: 'Poppins')),
        ]),
      ]),
    );
  }
}
