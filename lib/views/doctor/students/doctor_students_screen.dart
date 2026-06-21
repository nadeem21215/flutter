import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/user_images.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

// ─── Students List ────────────────────────────────────────────────────────────
class DoctorStudentsScreen extends StatefulWidget {
  const DoctorStudentsScreen({super.key});

  @override
  State<DoctorStudentsScreen> createState() => _DoctorStudentsScreenState();
}

class _DoctorStudentsScreenState extends State<DoctorStudentsScreen> {
  final _api = ApiService();
  List<StudentModel> _all = [];
  List<StudentModel> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<UserProvider>().firebaseUid ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getDoctorStudents(firebaseUid: uid);
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } on HttpException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _search(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all
              .where((s) => s.name.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Students'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DoctorStudentDetailScreen(student: s),
                                  )),
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
        decoration: BoxDecoration(
          color: AppColors.cardGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accentMedium.withOpacity(0.3),
            backgroundImage: UserImages.getImageBytes(student.studentCode) !=
                    null
                ? MemoryImage(UserImages.getImageBytes(student.studentCode)!)
                : null,
            child: UserImages.getImageBytes(student.studentCode) == null
                ? const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 26)
                : null,
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(student.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontFamily: 'Poppins')),
            if (student.level != null)
              Text(student.level!,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textBlue,
                      fontFamily: 'Poppins')),
          ]),
        ]),
      );
}

// ─── Student Detail (Doctor view) ────────────────────────────────────────────
class DoctorStudentDetailScreen extends StatelessWidget {
  final StudentModel student;
  const DoctorStudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Students'),
          // Was previously a right-aligned arrow_forward acting as "back",
          // which is inconsistent with every other screen's back affordance.
          // Replaced with the standard left-aligned back arrow.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student header
              Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentMedium.withOpacity(0.3),
                  backgroundImage:
                      UserImages.getImageBytes(student.studentCode) != null
                          ? MemoryImage(
                              UserImages.getImageBytes(student.studentCode)!)
                          : null,
                  child: UserImages.getImageBytes(student.studentCode) == null
                      ? const Icon(Icons.person_rounded,
                          size: 32, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontFamily: 'Poppins')),
                  Text(student.level ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontFamily: 'Poppins')),
                ]),
              ]),

              const SizedBox(height: 20),

              // Stats row
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _StatCol(label: 'Warnings', value: '${student.warnings ?? 0}'),
                _StatCol(
                    label: 'Credit Hours',
                    value: '${student.creditHours ?? 0}'),
                _StatCol(
                    label: 'GPA',
                    value: (student.gpa ?? 0.0).toStringAsFixed(1)),
              ]),

              const SizedBox(height: 24),

              // Courses
              ...student.courses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CourseTileBlue(
                        name: c.name, code: c.code, creditHours: c.creditHours),
                  )),
            ],
          ),
        ),
      );
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
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
