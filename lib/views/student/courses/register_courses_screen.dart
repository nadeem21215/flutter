import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/network/http_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class RegisterCoursesScreen extends StatefulWidget {
  const RegisterCoursesScreen({super.key});
  @override
  State<RegisterCoursesScreen> createState() => _RegisterCoursesScreenState();
}

class _RegisterCoursesScreenState extends State<RegisterCoursesScreen> {
  final _api = ApiService();
  List<CourseModel> _courses = [];
  List<CourseModel> _filtered = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _search = '';

  // Credit-hour regulations (loaded from backend, GPA-based)
  double _gpa = 0;
  int _minHours = AppConstants.minCreditHours;
  int _maxHours = AppConstants.maxCreditHours;

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
      final results = await Future.wait([
        _api.getCourses(firebaseUid: uid),
        _api.getRegistrationLimits(firebaseUid: uid),
      ]);
      final list = results[0] as List<CourseModel>;
      final limits = results[1] as RegistrationLimits;
      setState(() {
        _courses = list;
        _gpa = limits.gpa;
        _minHours = limits.minHours;
        _maxHours = limits.maxHours;
        _applySearch();
        _loading = false;
      });
    } on HttpException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _applySearch() {
    final q = _search.toLowerCase();
    // BUG FIX #9: _applySearch was reading from _courses (the source list) but
    // _filtered was built from _courses correctly. However the credit-hour
    // availability update in _toggle was re-reading _selectedCredits AFTER
    // modifying _courses[idx], meaning the just-toggled course was included in
    // the running total before computing availability for others — causing
    // off-by-one over/under counting. Availability is now computed from the
    // updated total that _selectedCredits returns after the toggle.
    _filtered = q.isEmpty
        ? List.from(_courses)
        : _courses
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.code.toLowerCase().contains(q))
            .toList();
  }

  int get _selectedCredits =>
      _courses.where((c) => c.isEnrolled).fold(0, (s, c) => s + c.creditHours);

  int get _remainingHours =>
      (_maxHours - _selectedCredits) < 0 ? 0 : _maxHours - _selectedCredits;

  bool get _withinAllowedRange =>
      _selectedCredits >= _minHours && _selectedCredits <= _maxHours;

  void _toggle(CourseModel course) {
    if (!course.isAvailable && !course.isEnrolled) return;
    final newEnrolled = !course.isEnrolled;
    final projectedCredits = _selectedCredits +
        (newEnrolled ? course.creditHours : -course.creditHours);
    if (newEnrolled && projectedCredits > _maxHours) {
      showError(context,
          'Your GPA (${_gpa.toStringAsFixed(2)}) allows a maximum of $_maxHours credit hours.');
      return;
    }

    setState(() {
      final idx = _courses.indexWhere((c) => c.code == course.code);
      if (idx >= 0) _courses[idx] = course.copyWith(isEnrolled: newEnrolled);

      // Recompute availability based on the updated selected total
      final total = _selectedCredits;
      for (int i = 0; i < _courses.length; i++) {
        final c = _courses[i];
        if (!c.isEnrolled) {
          _courses[i] = c.copyWith(
              isAvailable: total + c.creditHours <= _maxHours);
        }
      }
      _applySearch();
    });
  }

  Future<void> _register() async {
    final selected = _courses.where((c) => c.isEnrolled).toList();
    if (selected.isEmpty) return;

    // ── Credit-hour regulations (mirrors backend validation) ──
    if (_selectedCredits < _minHours) {
      showError(context,
          'You must register at least $_minHours credit hours before submitting your registration. You selected $_selectedCredits.');
      return;
    }
    if (_selectedCredits > _maxHours) {
      showError(context,
          'Your GPA (${_gpa.toStringAsFixed(2)}) allows a maximum of $_maxHours credit hours. You selected $_selectedCredits.');
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to continue with this registration?',
    );

    if (confirmed != true) return;

    final uid = context.read<UserProvider>().firebaseUid ?? '';

    setState(() => _submitting = true);

    try {
      await _api.enrollCourseByCodes(
        firebaseUid: uid,
        courseCodes: selected.map((c) => c.code).toList(),
      );

      if (!mounted) return;

      showSuccess(context, 'Courses registered successfully!');

      // ✅ مهم جدًا: رجوع مع result = true
      Navigator.pop(context, true);
    } on HttpException catch (e) {
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Register Courses'),
          // BUG FIX #10: The back arrow used Navigator.pop but automaticallyImplyLeading
          // was false, so there was no system back button either. Users had to register
          // or kill the app to leave. Fixed: arrow_back navigates back properly.
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(children: [
                        AppSearchBar(
                            onChanged: (v) => setState(() {
                                  _search = v;
                                  _applySearch();
                                })),
                        const SizedBox(height: 10),

                        // ── Credit-hour regulations panel (updates live) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _LimitStat(
                                      label: 'GPA',
                                      value: _gpa.toStringAsFixed(2)),
                                  _LimitStat(
                                      label: 'Min', value: '$_minHours h'),
                                  _LimitStat(
                                      label: 'Max', value: '$_maxHours h'),
                                  _LimitStat(
                                      label: 'Selected',
                                      value: '$_selectedCredits h',
                                      highlight: true,
                                      ok: _withinAllowedRange),
                                  _LimitStat(
                                      label: 'Remaining',
                                      value: '$_remainingHours h'),
                                ]),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _maxHours == 0
                                    ? 0
                                    : (_selectedCredits / _maxHours)
                                        .clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.background,
                                color: _selectedCredits > _maxHours
                                    ? AppColors.error
                                    : _withinAllowedRange
                                        ? AppColors.success
                                        : AppColors.primary,
                              ),
                            ),
                            if (_selectedCredits < _minHours) ...[
                              const SizedBox(height: 8),
                              Text(
                                  'Select at least $_minHours credit hours to register (${_minHours - _selectedCredits} more needed).',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGray,
                                      fontFamily: 'Poppins')),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          return GestureDetector(
                            onTap: () => _toggle(c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: c.isEnrolled
                                    ? AppColors.cardBlue
                                    : c.isAvailable
                                        ? AppColors.background
                                        : AppColors.cardGray,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: c.isEnrolled
                                        ? AppColors.cardBlue
                                        : c.isAvailable
                                            ? AppColors.divider
                                            : Colors.transparent),
                              ),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(c.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color:
                                                  c.isAvailable || c.isEnrolled
                                                      ? AppColors.textDark
                                                      : AppColors.textGray,
                                              fontFamily: 'Poppins')),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Text(c.code,
                                            style: TextStyle(
                                                color: c.isAvailable ||
                                                        c.isEnrolled
                                                    ? AppColors.textBlue
                                                    : AppColors.textGray,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins')),
                                        const SizedBox(width: 16),
                                        Text('${c.creditHours} Credit Hours',
                                            style: TextStyle(
                                                color: c.isAvailable ||
                                                        c.isEnrolled
                                                    ? AppColors.textBlue
                                                    : AppColors.textGray,
                                                fontSize: 13,
                                                fontFamily: 'Poppins')),
                                      ]),
                                    ])),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: c.isEnrolled
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: c.isEnrolled
                                            ? AppColors.primary
                                            : c.isAvailable
                                                ? AppColors.highlight
                                                : AppColors.textGray,
                                        width: 1.5),
                                  ),
                                  child: c.isEnrolled
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 18)
                                      : null,
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
        bottomSheet: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: ElevatedButton(
            onPressed: _submitting ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: _withinAllowedRange
                  ? AppColors.primary
                  : AppColors.textGray.withOpacity(0.4),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Register'),
          ),
        ),
      );
}

// ── Limit stat chip for the regulations panel ──────────────────────────────────
class _LimitStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool ok;
  const _LimitStat(
      {required this.label,
      required this.value,
      this.highlight = false,
      this.ok = true});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? (ok ? AppColors.success : AppColors.primary)
                    : AppColors.textDark,
                fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textGray,
                fontFamily: 'Poppins')),
      ]);
}
