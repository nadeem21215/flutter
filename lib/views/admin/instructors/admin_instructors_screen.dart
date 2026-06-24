import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../doctor/profile/doctor_profile_screen.dart' show DoctorNetworkAvatar;

// ─── Instructor List Screen ───────────────────────────────────────────────────
class AdminInstructorsScreen extends StatefulWidget {
  const AdminInstructorsScreen({super.key});

  @override
  State<AdminInstructorsScreen> createState() => _AdminInstructorsScreenState();
}

class _AdminInstructorsScreenState extends State<AdminInstructorsScreen> {
  final _api = ApiService();
  List<InstructorModel> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getInstructors();
      setState(() { _all = list; _filtered = list; _loading = false; });
    } on HttpException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load instructors'; _loading = false; });
    }
  }

  void _search(String q) => setState(() {
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all
            .where((i) => i.name.toLowerCase().contains(q.toLowerCase()))
            .toList();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Instructors'),
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
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('No instructors found.',
                                style: TextStyle(
                                    color: AppColors.textGray,
                                    fontFamily: 'Poppins')))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final inst = _filtered[i];
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminInstructorDetailScreen(
                                              instructor: inst),
                                    ),
                                  );
                                  _load();
                                },
                                child: _InstructorRow(instructor: inst),
                              );
                            },
                          ),
                  ),
                ),
              ]),
  );
}

// ─── Instructor Row Card ──────────────────────────────────────────────────────
class _InstructorRow extends StatelessWidget {
  final InstructorModel instructor;
  const _InstructorRow({required this.instructor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
        color: AppColors.cardGray,
        borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      DoctorNetworkAvatar(
        url:    instructor.profilePictureUrl,
        radius: 24,
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(instructor.name,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins')),
          const Text('Instructor',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBlue,
                  fontFamily: 'Poppins')),
        ]),
      ),
      const Icon(Icons.chevron_right_rounded,
          color: AppColors.textGray, size: 22),
    ]),
  );
}

// ─── Instructor Detail Screen ─────────────────────────────────────────────────
class AdminInstructorDetailScreen extends StatefulWidget {
  final InstructorModel instructor;
  const AdminInstructorDetailScreen({super.key, required this.instructor});

  @override
  State<AdminInstructorDetailScreen> createState() =>
      _AdminInstructorDetailScreenState();
}

class _AdminInstructorDetailScreenState
    extends State<AdminInstructorDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late InstructorModel _instructor;
  List<CourseModel> _courses = [];
  bool _loadingCourses = true;
  bool _uploading = false;
  String? _courseError;
  late TabController _tabs;
  int _imageVersion = 0;

  @override
  void initState() {
    super.initState();
    _instructor = widget.instructor;
    _tabs = TabController(length: 1, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() { _loadingCourses = true; _courseError = null; });
    try {
      final result = await _api
          .getInstructorWithCourses(firebaseUid: _instructor.firebaseUid);
      setState(() {
        _courses = result['courses'] as List<CourseModel>;
        _loadingCourses = false;
      });
    } on HttpException catch (e) {
      setState(() { _courseError = e.message; _loadingCourses = false; });
    } catch (e) {
      setState(() {
        _courseError = 'Failed to load courses';
        _loadingCourses = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      await _api.uploadProfilePicture(
        firebaseUid: _instructor.firebaseUid,
        filename:    file.name,
        fileBytes:   file.bytes!,
      );
      if (!mounted) return;
      final newUrl = _api.getProfilePictureUrl(_instructor.firebaseUid);
      setState(() {
        _imageVersion++;
        _instructor = _instructor.copyWith(
          profilePictureUrl: '$newUrl?v=$_imageVersion',
        );
      });
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

  Future<void> _removeCourse(CourseModel course) async {
    final ok = await showConfirmDialog(
        context: context,
        message: 'Remove "${course.name}" from this instructor?');
    if (ok != true) return;
    try {
      await _api.removeCourseFromInstructor(courseCode: course.code);
      if (!mounted) return;
      setState(() =>
          _courses = _courses.where((c) => c.code != course.code).toList());
      showSuccess(context, '${course.name} removed');
    } on HttpException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    }
  }

  Future<void> _showAssignCourseDialog() async {
    List<CourseModel> available = [];
    bool loadingCourses = true;
    final assignedCodes = _courses.map((c) => c.code).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loadingCourses) {
            loadingCourses = false;
            _api.getAllCourses().then((list) {
              setS(() {
                available = list
                    .where((c) => !assignedCodes.contains(c.code))
                    .toList();
              });
            });
          }

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(children: [
                const Text('Assign Course',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 16),
                if (loadingCourses)
                  const Expanded(child: AppLoading())
                else ...[
                  if (available.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No unassigned courses available.',
                            style: TextStyle(
                                color: AppColors.textGray,
                                fontFamily: 'Poppins')),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: ListView.separated(
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = available[i];
                          final selected = c.isEnrolled;
                          return GestureDetector(
                            onTap: () => setS(() {
                              available[i] = c.copyWith(isEnrolled: !selected);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.cardBlue
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: selected
                                        ? AppColors.highlight
                                        : AppColors.divider),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.textDark,
                                              fontFamily: 'Poppins')),
                                      Text(
                                          '${c.code}   ${c.creditHours} Credit Hours',
                                          style: const TextStyle(
                                              color: AppColors.textBlue,
                                              fontSize: 12,
                                              fontFamily: 'Poppins')),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.highlight,
                                        width: 1.5),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 16)
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
                        final toAssign =
                            available.where((c) => c.isEnrolled).toList();
                        if (toAssign.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        try {
                          for (final c in toAssign) {
                            await _api.assignCourseToInstructor(
                              courseCode: c.code,
                              instructorUid: _instructor.firebaseUid,
                            );
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await _loadCourses();
                          if (!mounted) return;
                          showSuccess(context, 'Courses assigned successfully');
                        } on HttpException catch (e) {
                          if (!mounted) return;
                          showError(context, e.message);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Assign'),
                    ),
                  ],
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _instructor.name);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Instructor',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _api.updateInstructorName(
                  firebaseUid: _instructor.firebaseUid,
                  name: newName,
                );
                setState(() {
                  _instructor = _instructor.copyWith(name: newName);
                });
                if (mounted) showSuccess(context, 'Instructor updated');
              } on HttpException catch (e) {
                if (mounted) showError(context, e.message);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Instructors'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit instructor',
          onPressed: _showEditDialog,
        ),
      ],
    ),
    body: Column(children: [
      // ── Profile header ────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(children: [
          Row(children: [
            // Avatar + camera button overlay
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                DoctorNetworkAvatar(
                  url: _instructor.profilePictureUrl != null
                      ? '${_instructor.profilePictureUrl}?v=$_imageVersion'
                      : null,
                  radius: 32,
                ),
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_instructor.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontFamily: 'Poppins')),
                    const Text('Instructor',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            fontFamily: 'Poppins')),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatCol(
                label: 'Courses',
                value: _loadingCourses ? '—' : '${_courses.length}'),
            _StatCol(label: 'Department', value: 'CS'),
            _StatCol(label: 'Role', value: 'Doctor'),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.textDark,
            unselectedLabelColor: AppColors.textGray,
            labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins'),
            unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins'),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [Tab(text: 'Assigned Courses')],
          ),
        ]),
      ),

      // ── Tab content ───────────────────────────────────────────────────
      Expanded(
        child: _loadingCourses
            ? const AppLoading()
            : _courseError != null
                ? AppError(
                    message: _courseError!, onRetry: _loadCourses)
                : _courses.isEmpty
                    ? const Center(
                        child: Text('No courses assigned.',
                            style: TextStyle(
                                color: AppColors.textGray,
                                fontFamily: 'Poppins')))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 90),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = _courses[i];
                          return CourseTileBlue(
                            name: c.name,
                            code: c.code,
                            creditHours: c.creditHours,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded,
                                  color: AppColors.textGray),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              onSelected: (v) {
                                if (v == 'remove') _removeCourse(c);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove Course',
                                      style: TextStyle(
                                          color: AppColors.textRed,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins')),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    ]),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.primary,
      onPressed: _showAssignCourseDialog,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
  );
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) =>
      Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
                fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontFamily: 'Poppins')),
      ]);
}
