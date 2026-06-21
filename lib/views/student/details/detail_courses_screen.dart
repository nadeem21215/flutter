import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

// ─── All Courses List ─────────────────────────────────────────────────────────
class DetailCoursesScreen extends StatefulWidget {
  const DetailCoursesScreen({super.key});

  @override
  State<DetailCoursesScreen> createState() => _DetailCoursesScreenState();
}

class _DetailCoursesScreenState extends State<DetailCoursesScreen> {
  final _api = ApiService();
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  // [FIX #7] Load all courses from /curriculum endpoint
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.getAllCourses();
      setState(() { _courses = res; _loading = false; });
    } on HttpException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('All Courses'),
      // This screen also serves as a bottom-nav tab inside StudentShell;
      // only show the back arrow when there's a previous route to pop to.
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
                        Center(child: Text('No courses available.',
                            style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins'))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = _courses[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => CourseDetailScreen(course: c))),
                            child: CourseTileBlue(
                              name:        c.name,
                              code:        c.code,
                              creditHours: c.creditHours,
                            ),
                          );
                        },
                      ),
              ),
  );
}

// ─── Course Detail Screen ─────────────────────────────────────────────────────
class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _api = ApiService();
  CourseModel? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // [FIX #7] Fetch real course detail from /course/{code}
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await _api.getCourseDetail(courseCode: widget.course.code);
      setState(() { _detail = detail; _loading = false; });
    } on HttpException catch (e) {
      // fallback to the data we already have from the list
      setState(() { _detail = widget.course; _loading = false; _error = e.message; });
    } catch (e) {
      setState(() { _detail = widget.course; _loading = false; });
    }
  }

  /// The course's own instructor (or an admin) may edit the description.
  bool _canEditDescription(BuildContext context, CourseModel c) {
    final user = context.read<UserProvider>();
    if (user.role == 'admin') return true;
    return user.role == 'doctor' &&
        c.doctorUid.isNotEmpty &&
        c.doctorUid == user.firebaseUid;
  }

  Future<void> _editDescription(CourseModel c) async {
    final ctrl = TextEditingController(text: c.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Course Description', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textDark, fontFamily: 'Poppins')),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          style: const TextStyle(
              color: AppColors.textDark, fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Write a description for this course…',
            hintStyle: const TextStyle(
                color: AppColors.textGray, fontFamily: 'Poppins', fontSize: 13),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(
                color: AppColors.textGray, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600,
                fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    try {
      await _api.updateCourseDescription(
        courseCode: c.code,
        doctorUid: uid,
        description: ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Description updated.'),
        backgroundColor: AppColors.success,
      ));
      _load();
    } on HttpException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _detail ?? widget.course;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Course Details'),
        // [FIX #4] Back button works correctly
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Name + code + hours
                  Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textDark, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(c.code, style: const TextStyle(color: AppColors.textBlue, fontSize: 13,
                        fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                    const SizedBox(width: 16),
                    Text('${c.creditHours} Credit Hours',
                        style: const TextStyle(color: AppColors.textBlue, fontSize: 13, fontFamily: 'Poppins')),
                    if (c.isElective) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Elective', style: TextStyle(color: AppColors.primary,
                            fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // [FIX #7] Instructor from DB
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Instructor',
                    value: c.doctorName.isNotEmpty ? c.doctorName : 'Not assigned',
                  ),
                  const SizedBox(height: 12),

                  // [FIX #5/#7] Schedule from DB
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Schedule',
                    value: c.timeRange.isNotEmpty
                        ? '${c.days}  •  ${c.timeRange}'
                        : 'Not scheduled',
                  ),
                  const SizedBox(height: 12),

                  // Hall
                  _DetailRow(
                    icon: Icons.room_rounded,
                    label: 'Lecture Hall',
                    value: c.hall.isNotEmpty ? c.hall : 'TBA',
                  ),

                  if (c.targetYear != null || c.targetTerm != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.school_rounded,
                      label: 'Target',
                      value: 'Year ${c.targetYear ?? '?'} – Term ${c.targetTerm ?? '?'}',
                    ),
                  ],

                  if (c.prerequisiteCode != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Prerequisite',
                      value: c.prerequisiteName != null
                          ? '${c.prerequisiteName} (${c.prerequisiteCode})'
                          : c.prerequisiteCode!,
                    ),
                  ],

                  // ── Course Description ──
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.notes_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Description', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textDark, fontFamily: 'Poppins')),
                    const Spacer(),
                    if (_canEditDescription(context, c))
                      GestureDetector(
                        onTap: () => _editDescription(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit_rounded, size: 13, color: AppColors.textBlue),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(
                                color: AppColors.textBlue, fontSize: 12,
                                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                          ]),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      c.description.isNotEmpty
                          ? c.description
                          : 'No description has been added for this course yet.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Poppins',
                        color: c.description.isNotEmpty
                            ? AppColors.textDark
                            : AppColors.textGray,
                        fontStyle: c.description.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: RichText(text: TextSpan(
        style: const TextStyle(fontSize: 14, fontFamily: 'Poppins', color: AppColors.textDark),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textGray)),
        ],
      ))),
    ],
  );
}
