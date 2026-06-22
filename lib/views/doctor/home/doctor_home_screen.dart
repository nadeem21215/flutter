import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/user_images.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../assignments/doctor_assignments_screen.dart';
import '../../student/details/detail_courses_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _api = ApiService();
  late Future<List<CourseModel>>  _coursesFuture;
  late Future<List<ScheduleItem>> _scheduleFuture;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    _coursesFuture  = _api.getDoctorCourses(firebaseUid: uid);
    // [FIX #5] Use doctor schedule endpoint
    _scheduleFuture = _api.getDoctorSchedule(firebaseUid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final imageBytes = UserImages.getImageBytes(user.firebaseUid);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_load),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.cardGray,
                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null ? const Icon(Icons.person_rounded, color: AppColors.textGray, size: 28) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text('Hi ${user.name ?? 'Doctor'}!',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                color: AppColors.textDark, fontFamily: 'Poppins')),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ]),
                    const Text('Instructor', style: TextStyle(color: AppColors.textGray, fontSize: 13, fontFamily: 'Poppins')),
                  ]),
                ),
              ]),

              const SizedBox(height: 16),

              // ── ASSIGNMENTS BUTTON ──
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DoctorAssignmentsScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentMedium.withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.assignment_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Text('Assignments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textDark, fontFamily: 'Poppins')),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGray, size: 14),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              // My Courses
              const Text('My Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.textDark, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              FutureBuilder<List<CourseModel>>(
                future: _coursesFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(20), child: AppLoading());
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No courses assigned.', style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins')),
                    );
                  }
                  return Column(children: list.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    // [FIX #5] Show schedule info on each course tile
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: c))),
                      child: _DoctorCourseTile(course: c),
                    ),
                  )).toList());
                },
              ),

              const SizedBox(height: 28),

              // My Schedule  [FIX #5]
              const Text('My Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.textDark, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              FutureBuilder<List<ScheduleItem>>(
                future: _scheduleFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(20), child: AppLoading());
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No schedule available.', style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins')),
                    );
                  }
                  return Column(children: list.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ScheduleCard(
                      courseName:    s.courseName,
                      courseCode:    s.courseCode,
                      days:          s.days,
                      timeRange:     s.timeRange,
                      hall:          s.hall,
                      enrolledCount: s.enrolledCount,
                    ),
                  )).toList());
                },
              ),

              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Course tile for doctor — shows name, code, credit hours, and schedule inline
class _DoctorCourseTile extends StatelessWidget {
  final CourseModel course;
  const _DoctorCourseTile({required this.course});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(color: AppColors.cardGray, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
          color: AppColors.textDark, fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      Row(children: [
        Text(course.code, style: const TextStyle(color: AppColors.textBlue, fontSize: 13,
            fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
        const SizedBox(width: 12),
        Text('${course.creditHours} hrs', style: const TextStyle(color: AppColors.textBlue, fontSize: 13, fontFamily: 'Poppins')),
      ]),
      // [FIX #5] Show schedule if available
      if (course.timeRange.isNotEmpty) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textGray),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              course.hall.isNotEmpty
                  ? '${course.days}  •  ${course.timeRange}   @ ${course.hall}'
                  : '${course.days}  •  ${course.timeRange}',
              style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ],
    ]),
  );
}
