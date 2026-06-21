import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with WidgetsBindingObserver {
  final _api = ApiService();
  late Future<AdminStats> _statsFuture;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statsFuture = _api.getAdminStats();
    _autoRefresh = Timer.periodic(
        const Duration(seconds: 10), (_) => _refreshStats());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStats();
  }

  void _refreshStats() {
    if (!mounted) return;
    setState(() { _statsFuture = _api.getAdminStats(); });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshStats(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_rounded,
                          color: AppColors.textDark, size: 26),
                      const SizedBox(width: 12),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Smart Institute',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                fontFamily: 'Poppins')),
                        Text('System Control Panel',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGray,
                                fontFamily: 'Poppins')),
                      ]),
                      const Spacer(),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.cardGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: AppColors.textDark, size: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FutureBuilder<AdminStats>(
                    future: _statsFuture,
                    builder: (_, snap) {
                      final year = snap.data?.academicYear ?? '—';
                      return Text(year,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.highlight,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins'));
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Welcome Banner ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // Background school icon (decorative)
                        const Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.18,
                            child: Icon(Icons.account_balance_rounded,
                                size: 120,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 100, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back,',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      fontFamily: 'Poppins')),
                              Text('${user.name ?? 'Admin'}!',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFamily: 'Poppins')),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: Colors.white60, size: 14),
                                const SizedBox(width: 6),
                                Text(_getFormattedDate(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white60,
                                        fontFamily: 'Poppins')),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Overview ─────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Overview',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontFamily: 'Poppins')),
                ),
                const SizedBox(height: 12),

                FutureBuilder<AdminStats>(
                  future: _statsFuture,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: AppLoading(),
                      );
                    }
                    if (snap.hasError) {
                      return AppError(
                          message: 'Failed to load stats',
                          onRetry: _refreshStats);
                    }
                    final s = snap.data;
                    final registered = s?.registeredCount ?? 0;
                    final notRegistered = ((s?.studentCount ?? 0) - registered).clamp(0, 9999);

                    return Column(children: [
                      // ── Top 3 stat cards ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.menu_book_rounded,
                              iconColor: const Color(0xFF5B7EC9),
                              value: '${s?.courseCount ?? '--'}',
                              label: 'Courses',
                              underlineColor: const Color(0xFF5B7EC9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.school_rounded,
                              iconColor: const Color(0xFF43A047),
                              value: '${s?.studentCount ?? '--'}',
                              label: 'Students',
                              underlineColor: const Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.person_rounded,
                              iconColor: const Color(0xFF9C27B0),
                              value: '${s?.instructorCount ?? '--'}',
                              label: 'Instructors',
                              underlineColor: const Color(0xFF9C27B0),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 10),

                      // ── Bottom 3 stat cards ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.app_registration_rounded,
                              iconColor: const Color(0xFFFF9800),
                              value: '${s?.enrollmentCount ?? '--'}',
                              label: 'Total Enrollments',
                              underlineColor: const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.how_to_reg_rounded,
                              iconColor: const Color(0xFF43A047),
                              value: '$registered',
                              label: 'Registered',
                              underlineColor: const Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OverviewCard(
                              icon: Icons.person_off_rounded,
                              iconColor: const Color(0xFFE53935),
                              value: '$notRegistered',
                              label: 'Not Registered',
                              underlineColor: const Color(0xFFE53935),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // ── Enrollment Status donut ────────────────────────────
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Enrollment Status',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  fontFamily: 'Poppins')),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: _DonutChart(
                                enrolled: registered,
                                total: s?.studentCount ?? 1,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendRow(
                                  color: const Color(0xFF43A047),
                                  label: 'Registered',
                                  value: '$registered',
                                  pct: s != null && s.studentCount > 0
                                      ? (registered / s.studentCount * 100).round()
                                      : 0,
                                ),
                                const SizedBox(height: 14),
                                _LegendRow(
                                  color: const Color(0xFFE53935),
                                  label: 'Not Registered',
                                  value: '$notRegistered',
                                  pct: s != null && s.studentCount > 0
                                      ? (notRegistered / s.studentCount * 100).round()
                                      : 0,
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overview Card ────────────────────────────────────────────────────────────
class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color underlineColor;
  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.underlineColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textGray,
                fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 28,
          decoration: BoxDecoration(
            color: underlineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

// ─── Simple Donut Chart ────────────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final int enrolled;
  final int total;
  const _DonutChart({required this.enrolled, required this.total});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(enrolled: enrolled, total: total),
    child: Center(
      child: Text(
        total > 0 ? '${(enrolled / total * 100).round()}%' : '0%',
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontFamily: 'Poppins'),
      ),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  final int enrolled;
  final int total;
  const _DonutPainter({required this.enrolled, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    final strokeW = 18.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, -3.14 / 2, 2 * 3.14159, false, bgPaint);

    if (total > 0) {
      final sweep = (enrolled / total) * 2 * 3.14159;
      canvas.drawArc(rect, -3.14159 / 2, sweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.enrolled != enrolled || old.total != total;
}

// ─── Legend Row ───────────────────────────────────────────────────────────────
class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int pct;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 12, height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontFamily: 'Poppins')),
      Text('$value ($pct%)',
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontFamily: 'Poppins')),
    ]),
  ]);
}
