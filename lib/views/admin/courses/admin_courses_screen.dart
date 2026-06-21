import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _api = ApiService();
  List<CourseModel> _all      = [];
  List<CourseModel> _filtered = [];
  List<InstructorModel> _instructors = [];
  bool   _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() { super.initState(); _load(); _loadInstructors(); }

  Future<void> _loadInstructors() async {
    try {
      final list = await _api.getInstructors();
      if (mounted) setState(() => _instructors = list);
    } on HttpException {
      // Non-fatal: the instructor dropdown will just show "Not assigned"
      // until this succeeds on a retry (e.g. pull-to-refresh on this screen).
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getAllCourses();
      setState(() { _all = list; _applySearch(); _loading = false; });
    } on HttpException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  void _applySearch() {
    _filtered = _query.isEmpty
        ? List.from(_all)
        : _all.where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.code.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _search(String q) => setState(() { _query = q; _applySearch(); });

  // ── Delete course ──────────────────────────────────────────────────────────
  Future<void> _removeCourse(CourseModel course) async {
    final ok = await showConfirmDialog(
      context: context,
      message: 'Delete "${course.name}" (${course.code})? This cannot be undone.',
    );
    if (ok != true) return;
    try {
      await _api.removeCourse(courseId: course.id, courseCode: course.code);
      if (!mounted) return;
      showSuccess(context, '${course.name} deleted successfully');
      _load();
    } on HttpException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  // ── Add / Edit course sheet (course == null → add mode) ────────────────────
  void _showCourseSheet({CourseModel? course}) {
    final isEdit    = course != null;
    final nameCtrl  = TextEditingController(text: course?.name ?? '');
    final codeCtrl  = TextEditingController(text: course?.code ?? '');
    final hoursCtrl = TextEditingController(
        text: course != null ? '${course.creditHours}' : '');
    final prereqCtrl = TextEditingController(
        text: course?.prerequisiteCode ?? '');
    final descCtrl  = TextEditingController(text: course?.description ?? '');
    final hallCtrl  = TextEditingController(text: course?.hall ?? '');
    final daysCtrl  = TextEditingController(text: course?.days ?? '');
    final timeFromCtrl = TextEditingController(text: course?.timeFrom ?? '');
    final timeToCtrl   = TextEditingController(text: course?.timeTo ?? '');
    final formKey = GlobalKey<FormState>();

    int year = course?.targetYear ?? 1;
    int term = course != null && course.targetYear != null && course.targetTerm != null
        ? (course.targetTerm! - (course.targetYear! - 1) * 2).clamp(1, 2)
        : 1;
    bool elective = course?.isElective ?? false;
    bool saving = false;

    // Selected instructor uid ('' = Not assigned). Defaults to the course's
    // current instructor if that uid is present in the loaded instructor list;
    // otherwise falls back to "Not assigned" rather than silently dropping it.
    String selectedDoctorUid = (course?.doctorUid.isNotEmpty ?? false) &&
            _instructors.any((d) => d.firebaseUid == course!.doctorUid)
        ? course!.doctorUid
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 28,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(isEdit ? 'Edit Course' : 'Add New Course',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: AppColors.textDark, fontFamily: 'Poppins')),
                const SizedBox(height: 20),

                const _AddLabel('Course Name'),
                const SizedBox(height: 8),
                _AddField(ctrl: nameCtrl, hint: 'e.g. Data Structures'),
                const SizedBox(height: 16),

                const _AddLabel('Course Code'),
                const SizedBox(height: 8),
                _AddField(
                    ctrl: codeCtrl,
                    hint: 'e.g. CS 201',
                    ltr: true,
                    enabled: !isEdit), // code is the primary key
                if (isEdit)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Course code cannot be changed.',
                        style: TextStyle(fontSize: 11, color: AppColors.textGray,
                            fontFamily: 'Poppins')),
                  ),
                const SizedBox(height: 16),

                const _AddLabel('Credit Hours (1–6)'),
                const SizedBox(height: 8),
                _AddField(
                    ctrl: hoursCtrl, hint: 'e.g. 3', numeric: true,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 1 || n > 6) return 'Must be between 1 and 6';
                      return null;
                    }),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _AddLabel('Year'),
                    const SizedBox(height: 8),
                    _Dropdown(
                        value: year,
                        items: const [1, 2, 3, 4],
                        onChanged: (v) => setS(() => year = v ?? 1)),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _AddLabel('Term'),
                    const SizedBox(height: 8),
                    _Dropdown(
                        value: term,
                        items: const [1, 2],
                        onChanged: (v) => setS(() => term = v ?? 1)),
                  ])),
                ]),
                const SizedBox(height: 16),

                const _AddLabel('Prerequisite Code (optional)'),
                const SizedBox(height: 8),
                _AddField(ctrl: prereqCtrl, hint: 'e.g. CS 102', ltr: true, optional: true),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Elective Course',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textDark, fontFamily: 'Poppins')),
                  value: elective,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setS(() => elective = v),
                ),
                const SizedBox(height: 16),

                const _AddLabel('Course Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'A short overview of what this course covers…'),
                ),
                const SizedBox(height: 16),

                const _AddLabel('Instructor'),
                const SizedBox(height: 8),
                _InstructorDropdown(
                  instructors: _instructors,
                  value: selectedDoctorUid,
                  onChanged: (v) => setS(() => selectedDoctorUid = v ?? ''),
                ),
                if (_instructors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('No instructors found. Pull to refresh this list once instructor accounts exist.',
                        style: TextStyle(fontSize: 11, color: AppColors.textGray,
                            fontFamily: 'Poppins')),
                  ),
                const SizedBox(height: 20),

                const Text('Lecture Schedule',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textDark, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                const Text('Leave all three blank for "not scheduled yet", or fill in all three.',
                    style: TextStyle(fontSize: 11, color: AppColors.textGray, fontFamily: 'Poppins')),
                const SizedBox(height: 10),

                const _AddLabel('Classroom / Hall'),
                const SizedBox(height: 8),
                _AddField(ctrl: hallCtrl, hint: 'e.g. B-204', ltr: true, optional: true),
                const SizedBox(height: 16),

                const _AddLabel('Days'),
                const SizedBox(height: 8),
                _AddField(ctrl: daysCtrl, hint: 'e.g. Sun & Tue', optional: true,
                    validator: (v) => _scheduleGroupValidator(
                        v, daysCtrl, timeFromCtrl, timeToCtrl)),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _AddLabel('Start Time'),
                    const SizedBox(height: 8),
                    _AddField(
                        ctrl: timeFromCtrl, hint: '08:00 AM', ltr: true, optional: true,
                        validator: (v) => _scheduleGroupValidator(
                            v, daysCtrl, timeFromCtrl, timeToCtrl)),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _AddLabel('End Time'),
                    const SizedBox(height: 8),
                    _AddField(
                        ctrl: timeToCtrl, hint: '09:30 AM', ltr: true, optional: true,
                        validator: (v) => _scheduleGroupValidator(
                            v, daysCtrl, timeFromCtrl, timeToCtrl)),
                  ])),
                ]),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => saving = true);
                      try {
                        if (isEdit) {
                          await _api.updateCourse(
                            code:             course.code,
                            name:             nameCtrl.text.trim(),
                            creditHours:      int.parse(hoursCtrl.text.trim()),
                            targetYear:       year,
                            termInYear:       term,
                            isElective:       elective,
                            prerequisiteCode: prereqCtrl.text.trim(),
                            doctorUid:        selectedDoctorUid,
                            description:      descCtrl.text.trim(),
                            hall:             hallCtrl.text.trim(),
                            days:             daysCtrl.text.trim(),
                            timeFrom:         timeFromCtrl.text.trim(),
                            timeTo:           timeToCtrl.text.trim(),
                          );
                        } else {
                          await _api.addCourse(
                            name:             nameCtrl.text.trim(),
                            code:             codeCtrl.text.trim(),
                            creditHours:      int.parse(hoursCtrl.text.trim()),
                            targetYear:       year,
                            termInYear:       term,
                            isElective:       elective,
                            prerequisiteCode: prereqCtrl.text.trim(),
                            doctorUid:        selectedDoctorUid,
                            description:      descCtrl.text.trim(),
                            hall:             hallCtrl.text.trim(),
                            days:             daysCtrl.text.trim(),
                            timeFrom:         timeFromCtrl.text.trim(),
                            timeTo:           timeToCtrl.text.trim(),
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                        showSuccess(context,
                            isEdit ? 'Course updated successfully' : 'Course added successfully');
                      } on HttpException catch (e) {
                        setS(() => saving = false);
                        showError(context, e.message);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Save Changes' : 'Add'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Courses'),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return CourseTileBlue(
                          name:        c.name,
                          code:        c.code,
                          creditHours: c.creditHours,
                          trailing: _ThreeDotMenu(
                            onEdit:   () => _showCourseSheet(course: c),
                            onRemove: () => _removeCourse(c),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.primary,
      onPressed: () => _showCourseSheet(),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
  );
}

// ─── 3-dot menu ───────────────────────────────────────────────────────────────
class _ThreeDotMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _ThreeDotMenu({required this.onEdit, required this.onRemove});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGray),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (v) {
      if (v == 'edit') onEdit();
      if (v == 'remove') onRemove();
    },
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'edit',
        child: Row(children: [
          Icon(Icons.edit_rounded, size: 18, color: AppColors.textBlue),
          SizedBox(width: 8),
          Text('Edit Course',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins')),
        ]),
      ),
      const PopupMenuItem(
        value: 'remove',
        child: Row(children: [
          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textRed),
          SizedBox(width: 8),
          Text('Delete Course',
              style: TextStyle(color: AppColors.textRed, fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins')),
        ]),
      ),
    ],
  );
}

// ─── Form helpers ─────────────────────────────────────────────────────────────
class _AddLabel extends StatelessWidget {
  final String text;
  const _AddLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textDark, fontFamily: 'Poppins'));
}

class _AddField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool ltr;
  final bool numeric;
  final bool optional;
  final bool enabled;
  final String? Function(String?)? validator;
  const _AddField({required this.ctrl, required this.hint,
      this.ltr = false, this.numeric = false, this.optional = false,
      this.enabled = true, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    enabled: enabled,
    textDirection: ltr ? TextDirection.ltr : null,
    keyboardType: numeric ? TextInputType.number : null,
    decoration: InputDecoration(hintText: hint),
    validator: validator ??
        (optional
            ? null
            : (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
  );
}

class _Dropdown extends StatelessWidget {
  final int value;
  final List<int> items;
  final ValueChanged<int?> onChanged;
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(14),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text('$e',
                style: const TextStyle(fontSize: 14, color: AppColors.textDark,
                    fontFamily: 'Poppins'))))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

// ─── Instructor dropdown — admin picks by name, API stores doctor_uid ─────────
class _InstructorDropdown extends StatelessWidget {
  final List<InstructorModel> instructors;
  final String value; // '' = Not assigned
  final ValueChanged<String?> onChanged;
  const _InstructorDropdown({
    required this.instructors,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a stale selection that no longer exists in the list
    // (e.g. the instructor's account was removed) by falling back to ''.
    final validValue =
        value.isEmpty || instructors.any((d) => d.firebaseUid == value)
            ? value
            : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Not assigned',
                  style: TextStyle(fontSize: 14, color: AppColors.textGray,
                      fontFamily: 'Poppins')),
            ),
            ...instructors.map((d) => DropdownMenuItem(
                  value: d.firebaseUid,
                  child: Text(d.name,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark,
                          fontFamily: 'Poppins')),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Days, start time, and end time form a single lecture-schedule group:
/// either all three are filled in, or all three are left blank. This mirrors
/// the backend's validation so the admin gets the same feedback before
/// the request round-trip.
String? _scheduleGroupValidator(
  String? _,
  TextEditingController days,
  TextEditingController timeFrom,
  TextEditingController timeTo,
) {
  final values = [days.text.trim(), timeFrom.text.trim(), timeTo.text.trim()];
  final anyFilled = values.any((v) => v.isNotEmpty);
  final allFilled = values.every((v) => v.isNotEmpty);
  if (anyFilled && !allFilled) {
    return 'Fill in days, start time, and end time together, or leave all blank.';
  }
  return null;
}
