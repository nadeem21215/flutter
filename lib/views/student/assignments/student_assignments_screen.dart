import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final _api = ApiService();
  late Future<List<AssignmentModel>> _future;
  Map<int, SubmissionModel> _submissions = {};
  String _selectedCourse = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    _future = _api.getStudentAssignments(firebaseUid: uid);
    _api.getStudentSubmissions(firebaseUid: uid).then((list) {
      if (mounted) {
        setState(() =>
            _submissions = {for (final s in list) s.assignmentId: s});
      }
    }).catchError((_) {});
  }

  Future<void> _submit(AssignmentModel assignment) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (!mounted) return;
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    try {
      await _api.uploadSubmission(
        studentUid: uid,
        assignmentId: assignment.id,
        filename: picked.name,
        fileBytes: picked.bytes ?? [],
      );
      if (!mounted) return;
      showSuccess(context, 'Solution submitted successfully!');
      setState(_load);
    } catch (e) {
      if (mounted) {
        showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assignments',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        color: AppColors.primary,
        child: FutureBuilder<List<AssignmentModel>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoading());
            }
            if (snap.hasError) {
              return AppError(
                message: 'Could not load assignments.\nPull down to retry.',
                onRetry: () => setState(_load),
              );
            }

            final all = snap.data ?? [];

            if (all.isEmpty) {
              return const _EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No assignments yet',
                subtitle: 'Your instructors haven\'t uploaded\nany assignments yet.',
              );
            }

            // build course filter list
            final courses = <String>{''}; // '' = All
            for (final a in all) {
              courses.add(a.courseCode);
            }

            final filtered = all.where((a) {
              final matchCourse = _selectedCourse.isEmpty || a.courseCode == _selectedCourse;
              final q = _search.toLowerCase();
              final matchSearch = q.isEmpty ||
                  a.title.toLowerCase().contains(q) ||
                  a.courseName.toLowerCase().contains(q) ||
                  a.courseCode.toLowerCase().contains(q);
              return matchCourse && matchSearch;
            }).toList();

            return Column(
              children: [
                // ── Search + Filter bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(children: [
                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          hintText: 'Search assignments…',
                          hintStyle: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins', fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGray, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Course chips
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: courses.map((code) {
                          final isSelected = _selectedCourse == code;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCourse = code),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  code.isEmpty ? 'All' : code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: isSelected ? Colors.white : AppColors.textGray,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),

                // ── List ──
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                          subtitle: 'Try a different search or filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _AssignmentCard(
                            assignment: filtered[i],
                            submission: _submissions[filtered[i].id],
                            onSubmit: () => _submit(filtered[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Assignment Card ────────────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final SubmissionModel? submission;
  final VoidCallback onSubmit;
  const _AssignmentCard({
    required this.assignment,
    required this.submission,
    required this.onSubmit,
  });

  IconData get _icon {
    switch (assignment.fileExtension) {
      case 'PDF':  return Icons.picture_as_pdf_rounded;
      case 'DOC':
      case 'DOCX': return Icons.description_rounded;
      case 'ZIP':
      case 'RAR':  return Icons.folder_zip_rounded;
      case 'PNG':
      case 'JPG':
      case 'JPEG': return Icons.image_rounded;
      default:     return Icons.insert_drive_file_rounded;
    }
  }

  Color get _iconColor {
    switch (assignment.fileExtension) {
      case 'PDF':  return const Color(0xFFE53935);
      case 'DOC':
      case 'DOCX': return const Color(0xFF1976D2);
      case 'ZIP':
      case 'RAR':  return const Color(0xFFF57C00);
      default:     return AppColors.primary;
    }
  }

  String get _dueLabelText {
    if (assignment.dueDate.isEmpty) return '';
    try {
      final due = DateTime.parse(assignment.dueDate);
      final now = DateTime.now();
      final diff = due.difference(now).inDays;
      if (diff < 0)  return 'Overdue';
      if (diff == 0) return 'Due today';
      if (diff == 1) return 'Due tomorrow';
      return 'Due in $diff days';
    } catch (_) {
      return 'Due ${assignment.dueDate}';
    }
  }

  Color get _dueColor {
    if (assignment.dueDate.isEmpty) return Colors.transparent;
    try {
      final due = DateTime.parse(assignment.dueDate);
      final diff = due.difference(DateTime.now()).inDays;
      if (diff < 0)  return AppColors.error;
      if (diff <= 2) return AppColors.warning;
      return AppColors.success;
    } catch (_) {
      return AppColors.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // File type icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(assignment.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: AppColors.textDark, fontFamily: 'Poppins'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(assignment.courseCode,
                    style: const TextStyle(
                        color: AppColors.textBlue, fontSize: 11,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(assignment.courseName,
                  style: const TextStyle(color: AppColors.textGray, fontSize: 11, fontFamily: 'Poppins'),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ])),
          // Download button
          GestureDetector(
            onTap: () async {
              final url = api.getAssignmentDownloadUrl(assignment.id);
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) showError(context, 'Cannot open file.');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),

        if (assignment.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(assignment.description,
              style: const TextStyle(color: AppColors.textGray, fontSize: 12,
                  height: 1.4, fontFamily: 'Poppins'),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ],

        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.attach_file_rounded, size: 13, color: AppColors.textGray),
          const SizedBox(width: 4),
          Flexible(child: Text(assignment.filename,
              style: const TextStyle(color: AppColors.textGray, fontSize: 11, fontFamily: 'Poppins'),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Spacer(),
          if (_dueLabelText.isNotEmpty) ...[
            Icon(Icons.calendar_today_rounded, size: 11, color: _dueColor),
            const SizedBox(width: 3),
            Text(_dueLabelText,
                style: TextStyle(color: _dueColor, fontSize: 11,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ],
        ]),

        // ── Submission section ──
        const SizedBox(height: 12),
        if (submission != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Submitted',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
                    Text(submission!.filename,
                        style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                            fontFamily: 'Poppins'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ])),
              GestureDetector(
                onTap: onSubmit,
                child: const Text('Re-submit',
                    style: TextStyle(
                        color: AppColors.textBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ),
            ]),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSubmit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_rounded, size: 17),
              label: const Text('Submit Solution',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
            ),
          ),
      ]),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: AppColors.textGray.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textDark, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textGray,
                height: 1.5, fontFamily: 'Poppins')),
      ]),
    ),
  );
}
