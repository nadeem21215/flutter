import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final AssignmentModel assignment;
  const AssignmentSubmissionsScreen({super.key, required this.assignment});

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  final _api = ApiService();
  late Future<List<SubmissionModel>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    _future = _api.getAssignmentSubmissions(
        assignmentId: widget.assignment.id, doctorUid: uid);
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
        title: const Text('Submissions',
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        color: AppColors.primary,
        child: Column(children: [
          // ── Assignment header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.assignment.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontFamily: 'Poppins'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        '${widget.assignment.courseCode} — ${widget.assignment.courseName}',
                        style: const TextStyle(
                            color: AppColors.textBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Search by student name or code…',
                  hintStyle: TextStyle(
                      color: AppColors.textGray,
                      fontFamily: 'Poppins',
                      fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textGray, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: FutureBuilder<List<SubmissionModel>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoading());
                }
                if (snap.hasError) {
                  return AppError(
                    message: 'Could not load submissions.\nPull down to retry.',
                    onRetry: () => setState(_load),
                  );
                }

                final all = snap.data ?? [];
                final q = _search.toLowerCase();
                final filtered = all.where((s) {
                  return q.isEmpty ||
                      s.studentName.toLowerCase().contains(q) ||
                      s.studentCode.toLowerCase().contains(q);
                }).toList();

                if (all.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.inbox_outlined,
                            size: 56, color: AppColors.textGray),
                        SizedBox(height: 16),
                        Text('No submissions yet',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                fontFamily: 'Poppins')),
                        SizedBox(height: 8),
                        Text(
                            'Students haven\'t submitted any\nsolutions for this assignment yet.',
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

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No results',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            fontFamily: 'Poppins')),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _SubmissionTile(submission: filtered[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Submission Tile ────────────────────────────────────────────────────────────
class _SubmissionTile extends StatelessWidget {
  final SubmissionModel submission;
  const _SubmissionTile({required this.submission});

  String get _submittedLabel {
    if (submission.submittedAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(submission.submittedAt);
      return 'Submitted ${dt.toLocal().toString().split('.').first}';
    } catch (_) {
      return 'Submitted ${submission.submittedAt}';
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
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_rounded,
              color: AppColors.textBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(submission.studentName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardBlue,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(submission.studentCode,
                  style: const TextStyle(
                      color: AppColors.textBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.attach_file_rounded,
                size: 12, color: AppColors.textGray),
            const SizedBox(width: 3),
            Flexible(
                child: Text(submission.filename,
                    style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                        fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
          if (_submittedLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_submittedLabel,
                style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 10,
                    fontFamily: 'Poppins')),
          ],
        ])),
        const SizedBox(width: 8),
        // Download button
        GestureDetector(
          onTap: () async {
            final url = api.getSubmissionDownloadUrl(submission.id);
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
            child: const Icon(Icons.download_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}
