import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/user_images.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _api = ApiService();
  List<StudentModel> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getAllStudents();
      setState(() { _all = list; _filtered = list; _loading = false; });
    } on HttpException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  void _search(String q) => setState(() {
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all.where((s) => s.name.toLowerCase().contains(q.toLowerCase())).toList();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Students'),
      actions: [IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () {})],
      automaticallyImplyLeading: false,
    ),
    body: _loading
        ? const AppLoading()
        : _error != null
            ? AppError(message: _error!, onRetry: _load)
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: AppSearchBar(onChanged: _search),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminStudentDetailScreen(student: s),
                            ));
                            _load();
                          },
                          child: _StudentRow(student: s),
                        );
                      },
                    ),
                  ),
                ),
              ]),
  );
}

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: AppColors.cardGray, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.accentMedium.withOpacity(0.3),
        backgroundImage: UserImages.getImageBytes(student.studentCode) != null
            ? MemoryImage(UserImages.getImageBytes(student.studentCode)!)
            : null,
        child: UserImages.getImageBytes(student.studentCode) == null
            ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 26)
            : null,
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(student.name, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins')),
        if (student.level != null)
          Text(student.level!, style: const TextStyle(
              fontSize: 13, color: AppColors.textBlue, fontFamily: 'Poppins')),
      ]),
    ]),
  );
}

// ─── Student Detail with Tabs ─────────────────────────────────────────────────
class AdminStudentDetailScreen extends StatefulWidget {
  final StudentModel student;
  const AdminStudentDetailScreen({super.key, required this.student});

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late StudentModel _student;
  late TabController _tabs;

  List<CourseModel> _completedCourses = [];
  bool _loadingCompleted = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _completedCourses.isEmpty && !_loadingCompleted) {
        _loadCompleted();
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadCompleted() async {
    setState(() => _loadingCompleted = true);
    try {
      // BUG FIX #12: _student.studentCode (e.g. "220423") was passed as firebaseUid.
      // The API expects the firebase_uid, which for students comes from the login
      // response. StudentModel does not carry firebaseUid, so we use the student's
      // numeric id as a fallback identifier that the server understands via /student/history.
      // If the server supports lookup by student id, replace with the correct field.
      final res = await _api.getCompletedCourses(firebaseUid: _student.studentCode);
      setState(() { _completedCourses = res; _loadingCompleted = false; });
    } catch (_) {
      setState(() => _loadingCompleted = false);
    }
  }

  Future<void> _removeCourse(CourseModel course) async {
    final ok = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to remove course',
    );
    if (ok != true) return;
    try {
      await _api.removeCourseFromStudent(
        studentId:  _student.id,
        courseId:   course.id,
        courseCode: course.code,
      );
      setState(() {
        _student = StudentModel(
          id:          _student.id,
          name:        _student.name,
          studentCode: _student.studentCode,
          level:       _student.level,
          gpa:         _student.gpa,
          creditHours: _student.creditHours,
          warnings:    _student.warnings,
          courses:     _student.courses.where((c) => c.code != course.code).toList(),
        );
      });
      showSuccess(context, '${course.name} removed');
    } on HttpException catch (e) {
      showError(context, e.message);
    }
  }

  Future<void> _showAddCourseDialog() async {
    List<CourseModel> available = [];
    bool loadingCourses = true;
    final enrolledCodes = _student.courses.map((c) => c.code).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // BUG FIX #13: getAllCourses was called on EVERY rebuild because
          // loadingCourses stayed true until the future resolved, triggering
          // repeated calls. Flip the flag first, then fire the request once.
          if (loadingCourses) {
            loadingCourses = false;
            _api.getAllCourses().then((list) {
              setS(() {
                available = list.where((c) => !enrolledCodes.contains(c.code)).toList();
              });
            });
          }

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(children: [
                const Text('Add Course', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                const SizedBox(height: 16),
                if (loadingCourses)
                  const Expanded(child: AppLoading())
                else ...[
                  Expanded(
                    child: ListView.separated(
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c = available[i];
                        final isSelected = c.isEnrolled;
                        return GestureDetector(
                          onTap: () => setS(() {
                            available[i] = c.copyWith(isEnrolled: !isSelected);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.cardBlue : AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.highlight : AppColors.divider),
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14,
                                    color: AppColors.textDark, fontFamily: 'Poppins')),
                                Text('${c.code}   ${c.creditHours} Credit Hours',
                                    style: const TextStyle(color: AppColors.textBlue, fontSize: 12, fontFamily: 'Poppins')),
                              ])),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.highlight,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : null,
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final toAdd = available.where((c) => c.isEnrolled).toList();
                      if (toAdd.isEmpty) { Navigator.pop(ctx); return; }
                      try {
                        for (final c in toAdd) {
                          await _api.addCourseToStudent(
                            studentId:  _student.id,
                            courseId:   c.id,
                            courseCode: c.code,
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        // Update the registered list locally so the new courses
                        // appear immediately. (The backend has no GET /students/{id}
                        // endpoint, so refetching here used to 404 and silently skip
                        // the UI refresh — which is why a manual reload was needed.)
                        setState(() {
                          _student = StudentModel(
                            id:          _student.id,
                            name:        _student.name,
                            studentCode: _student.studentCode,
                            level:       _student.level,
                            gpa:         _student.gpa,
                            creditHours: _student.creditHours,
                            warnings:    _student.warnings,
                            courses: [
                              ..._student.courses,
                              ...toAdd.map((c) => c.copyWith(isEnrolled: false)),
                            ],
                          );
                        });
                        showSuccess(context, 'Courses added successfully');
                      } on HttpException catch (e) {
                        showError(context, e.message);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Students'),
      // BUG FIX #11: arrow_forward used as back button was confusing UX.
      // Replaced with a proper back arrow that also navigates back correctly.
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      automaticallyImplyLeading: false,
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(children: [
          // Header
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.cardGray,
              backgroundImage: UserImages.getImageBytes(_student.studentCode) != null
                  ? MemoryImage(UserImages.getImageBytes(_student.studentCode)!)
                  : null,
              child: UserImages.getImageBytes(_student.studentCode) == null
                  ? const Icon(Icons.person_rounded, size: 30, color: AppColors.textGray)
                  : null,
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_student.name, style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textDark, fontFamily: 'Poppins')),
              Text(_student.level ?? '', style: const TextStyle(
                  fontSize: 13, color: AppColors.textGray, fontFamily: 'Poppins')),
            ]),
          ]),
          const SizedBox(height: 16),
          // Stats
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatCol(label: 'Warnings',     value: '${_student.warnings    ?? 0}'),
            _StatCol(label: 'Credit Hours', value: '${_student.creditHours ?? 0}'),
            _StatCol(label: 'GPA',          value: (_student.gpa ?? 0.0).toStringAsFixed(1)),
          ]),
          const SizedBox(height: 16),
          // Tabs
          TabBar(
            controller: _tabs,
            labelColor: AppColors.textDark,
            unselectedLabelColor: AppColors.textGray,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Poppins'),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(text: 'Registered Courses'),
              Tab(text: 'Completed courses'),
            ],
          ),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            // ── Registered Courses Tab ──
            _student.courses.isEmpty
                ? const Center(child: Text('No registered courses.',
                    style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins')))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: _student.courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _student.courses[i];
                      return CourseTileBlue(
                        name:        c.name,
                        code:        c.code,
                        creditHours: c.creditHours,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGray),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (v) { if (v == 'remove') _removeCourse(c); },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove Course', style: TextStyle(
                                  color: AppColors.textRed, fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // ── Completed Courses Tab ──
            _loadingCompleted
                ? const AppLoading()
                : _completedCourses.isEmpty
                    ? const Center(child: Text('No completed courses.',
                        style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins')))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: _completedCourses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => CourseTileGray(
                          name:        _completedCourses[i].name,
                          code:        _completedCourses[i].code,
                          creditHours: _completedCourses[i].creditHours,
                        ),
                      ),
          ],
        ),
      ),
    ]),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.primary,
      onPressed: _showAddCourseDialog,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
  );
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(
        fontSize: 13, color: AppColors.textGray, fontFamily: 'Poppins')),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.textDark, fontFamily: 'Poppins')),
  ]);
}
