import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/user_images.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../courses/register_courses_screen.dart';
import '../assignments/student_assignments_screen.dart';
import '../chat/chat_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _api = ApiService();
  late Future<List<ScheduleItem>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    _scheduleFuture = _api.getSchedule(firebaseUid: uid);
  }

  void _onRegistered() {
    context.read<UserProvider>().markRegistered();
    setState(() { _loadSchedule(); });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final imageBytes = UserImages.getImageBytes(user.firebaseUid);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        backgroundColor: AppColors.primary,
        tooltip: 'Institute Assistant',
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_loadSchedule),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                Row(children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.cardGray,
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null
                        ? const Icon(Icons.person_rounded, color: AppColors.textGray, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Hi ${user.name ?? 'Student'}!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                              color: AppColors.textDark, fontFamily: 'Poppins')),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ]),
                    Text(user.level ?? 'Student',
                        style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontFamily: 'Poppins')),
                  ]),
                ]),

                const SizedBox(height: 20),

                // ── REGISTER CARD ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: user.hasRegistered
                        ? AppColors.primary.withOpacity(0.55)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Welcome to the\nSmart Institute App!',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white, height: 1.4, fontFamily: 'Poppins')),
                    const SizedBox(height: 8),
                    Text(
                      user.hasRegistered
                          ? 'You have already registered your courses for this term.'
                          : 'Register your courses easily and get smart recommendations.',
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 16),
                    if (user.hasRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Registered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: 'Poppins')),
                        ]),
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterCoursesScreen()));
                          if (result == true) _onRegistered();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Register Courses',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.primary, fontFamily: 'Poppins')),
                        ),
                      ),
                  ]),
                ),


                const SizedBox(height: 12),

                // ── ASSIGNMENTS BUTTON ──
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen())),
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

                const SizedBox(height: 24),

                // ── STATS ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatItem(label: 'Warnings',     value: '${user.warnings ?? 0}'),
                  _StatItem(label: 'Credit Hours', value: '${user.creditHours ?? 0}'),
                  _StatItem(label: 'GPA',          value: (user.gpa ?? 0.0).toStringAsFixed(1)),
                ]),

                const SizedBox(height: 28),

                // ── SCHEDULE ──
                const Text('My Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textDark, fontFamily: 'Poppins')),
                const SizedBox(height: 12),

                FutureBuilder<List<ScheduleItem>>(
                  future: _scheduleFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(24), child: AppLoading());
                    }
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardGray,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(children: [
                          Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textGray),
                          SizedBox(height: 10),
                          Text('No registered courses yet',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textDark, fontFamily: 'Poppins')),
                          SizedBox(height: 4),
                          Text('Register your courses to see your\nweekly schedule here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textGray, fontSize: 12,
                                  height: 1.5, fontFamily: 'Poppins')),
                        ]),
                      );
                    }
                    return Column(
                      children: items.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScheduleCard(
                          courseName: s.courseName,
                          courseCode: s.courseCode,
                          days:       s.days,
                          timeRange:  s.timeRange,
                          hall:       s.hall,
                          instructor: s.doctorName,
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontFamily: 'Poppins')),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.textDark, fontFamily: 'Poppins')),
  ]);
}
