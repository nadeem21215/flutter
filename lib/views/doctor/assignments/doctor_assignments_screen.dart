import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../student/assignments/assignment_submissions_screen.dart';

class DoctorAssignmentsScreen extends StatefulWidget {
  const DoctorAssignmentsScreen({super.key});

  @override
  State<DoctorAssignmentsScreen> createState() =>
      _DoctorAssignmentsScreenState();
}

class _DoctorAssignmentsScreenState extends State<DoctorAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabCtrl;

  // Upload form state
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCourseCode;
  String _dueDate = '';
  PlatformFile? _pickedFile;
  bool _uploading = false;
  List<CourseModel> _courses = [];
  bool _loadingCourses = true;

  // My assignments
  late Future<List<AssignmentModel>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCourses();
    _loadAssignments();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _loadCourses() async {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    try {
      final list = await _api.getDoctorCourses(firebaseUid: uid);
      if (mounted) {
        setState(() {
          _courses = list;
          _loadingCourses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  void _loadAssignments() {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    setState(() {
      _assignmentsFuture = _api.getDoctorAssignments(firebaseUid: uid);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (_selectedCourseCode == null ||
        _titleCtrl.text.trim().isEmpty ||
        _pickedFile == null) {
      showError(
          context, 'Please fill in all required fields and select a file.');
      return;
    }
    setState(() => _uploading = true);
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    try {
      await _api.uploadAssignment(
        doctorUid: uid,
        courseCode: _selectedCourseCode!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        filename: _pickedFile!.name,
        fileBytes: _pickedFile!.bytes ?? [],
      );
      if (!mounted) return;
      showSuccess(context, 'Assignment uploaded successfully!');
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _selectedCourseCode = null;
        _dueDate = '';
        _pickedFile = null;
      });
      _loadAssignments();
      _tabCtrl.animateTo(1); // switch to My Assignments tab
    } catch (e) {
      if (mounted) {
        showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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
        title: const Text('Assignments',
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGray,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
          tabs: const [
            Tab(text: 'Upload'),
            Tab(text: 'My Assignments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildUploadTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  // ── Upload Tab ─────────────────────────────────────────────────────────────
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Course selector
        const _Label('Course *'),
        const SizedBox(height: 6),
        _loadingCourses
            ? const Center(child: AppLoading())
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCourseCode,
                    hint: const Text('Select a course',
                        style: TextStyle(
                            color: AppColors.textGray,
                            fontFamily: 'Poppins',
                            fontSize: 13)),
                    items: _courses
                        .map((c) => DropdownMenuItem(
                              value: c.code,
                              child: Text('${c.code} — ${c.name}',
                                  style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontFamily: 'Poppins',
                                      fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCourseCode = v),
                  ),
                ),
              ),

        const SizedBox(height: 16),

        // Title
        const _Label('Title *'),
        const SizedBox(height: 6),
        _InputField(
            controller: _titleCtrl, hint: 'e.g. Midterm Project — Phase 1'),

        const SizedBox(height: 16),

        // Description
        const _Label('Description (optional)'),
        const SizedBox(height: 6),
        _InputField(
            controller: _descCtrl,
            hint: 'Instructions, rubric, or notes…',
            maxLines: 3),

        const SizedBox(height: 16),

        // Due date
        const _Label('Due Date (optional)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: AppColors.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(
                  () => _dueDate = picked.toIso8601String().split('T').first);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.textGray),
              const SizedBox(width: 10),
              Text(
                _dueDate.isEmpty ? 'Pick a due date' : _dueDate,
                style: TextStyle(
                  color: _dueDate.isEmpty
                      ? AppColors.textGray
                      : AppColors.textDark,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              if (_dueDate.isNotEmpty) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _dueDate = ''),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textGray),
                ),
              ],
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // File picker
        const _Label('File *'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pickedFile != null
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Column(children: [
              Icon(
                _pickedFile != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                color: _pickedFile != null
                    ? AppColors.success
                    : AppColors.textGray,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                _pickedFile != null
                    ? _pickedFile!.name
                    : 'Tap to select a file',
                style: TextStyle(
                  color: _pickedFile != null
                      ? AppColors.textDark
                      : AppColors.textGray,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight:
                      _pickedFile != null ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (_pickedFile != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                      fontFamily: 'Poppins'),
                ),
              ],
            ]),
          ),
        ),

        const SizedBox(height: 28),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _uploading ? null : _upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: Text(
              _uploading ? 'Uploading…' : 'Upload Assignment',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  // ── List Tab ───────────────────────────────────────────────────────────────
  Widget _buildListTab() {
    return FutureBuilder<List<AssignmentModel>>(
      future: _assignmentsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoading());
        }
        if (snap.hasError) {
          return AppError(
              message: 'Could not load assignments.',
              onRetry: _loadAssignments);
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.assignment_outlined,
                    size: 56, color: AppColors.textGray),
                SizedBox(height: 16),
                Text('No assignments uploaded yet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins')),
                SizedBox(height: 8),
                Text('Use the Upload tab to add assignments\nfor your courses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                        height: 1.5,
                        fontFamily: 'Poppins')),
              ]),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _DoctorAssignmentTile(
            assignment: list[i],
            onViewSubmissions: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssignmentSubmissionsScreen(assignment: list[i]),
                ),
              );
            },
            onDelete: () async {
              final uid = context.read<UserProvider>().firebaseUid ?? '';
              try {
                await _api.deleteAssignment(
                    assignmentId: list[i].id, doctorUid: uid);
                if (ctx.mounted) showSuccess(ctx, 'Assignment deleted.');
                _loadAssignments();
              } catch (e) {
                if (ctx.mounted) showError(ctx, 'Delete failed.');
              }
            },
          ),
        );
      },
    );
  }
}

// ── Doctor Assignment Tile ─────────────────────────────────────────────────────
class _DoctorAssignmentTile extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onDelete;
  final VoidCallback onViewSubmissions;
  const _DoctorAssignmentTile(
      {required this.assignment,
      required this.onDelete,
      required this.onViewSubmissions});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewSubmissions,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: AppColors.textBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(assignment.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(assignment.courseCode,
                        style: const TextStyle(
                            color: AppColors.textBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(assignment.filename,
                          style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11,
                              fontFamily: 'Poppins'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ]),
                if (assignment.dueDate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textGray),
                    const SizedBox(width: 3),
                    Text('Due ${assignment.dueDate}',
                        style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                            fontFamily: 'Poppins')),
                  ]),
                ],
              ])),
          IconButton(
            onPressed: onViewSubmissions,
            tooltip: 'View submissions',
            icon: const Icon(Icons.people_alt_rounded,
                color: AppColors.textBlue, size: 20),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context: context,
                message: 'Delete this assignment?',
              );
              if (confirm == true) onDelete();
            },
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textGray, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          fontFamily: 'Poppins'));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _InputField(
      {required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textDark, fontFamily: 'Poppins', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
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
      );
}
