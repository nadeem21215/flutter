import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─── Loading ──────────────────────────────────────────────────────────────────
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(AppColors.primary),
      strokeWidth: 2.5,
    ),
  );
}

// ─── Error ────────────────────────────────────────────────────────────────────
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.signal_wifi_off_rounded, color: AppColors.textGray, size: 48),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ]),
    ),
  );
}

// ─── Course Card (gray, unselected style) ─────────────────────────────────────
class CourseTileGray extends StatelessWidget {
  final String name;
  final String code;
  final int    creditHours;
  const CourseTileGray({super.key, required this.name, required this.code, required this.creditHours});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardGray,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Row(children: [
        Text(code,        style: const TextStyle(color: AppColors.textBlue, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Text('$creditHours Credit Hours', style: const TextStyle(color: AppColors.textBlue, fontSize: 13)),
      ]),
    ]),
  );
}

// ─── Course Card (blue, enrolled/selected style) ──────────────────────────────
class CourseTileBlue extends StatelessWidget {
  final String    name;
  final String    code;
  final int       creditHours;
  final Widget?   trailing;
  const CourseTileBlue({super.key, required this.name, required this.code,
      required this.creditHours, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBlue,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Row(children: [
          Text(code,        style: const TextStyle(color: AppColors.textBlue, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Text('$creditHours Credit Hours', style: const TextStyle(color: AppColors.textBlue, fontSize: 13)),
        ]),
      ])),
      if (trailing != null) trailing!,
    ]),
  );
}

// ─── Schedule Card ────────────────────────────────────────────────────────────
class ScheduleCard extends StatelessWidget {
  final String courseName;
  final String days;
  final String timeRange;
  final String hall;
  final String courseCode;
  final String instructor;
  final int?   enrolledCount;
  const ScheduleCard({
    super.key,
    required this.courseName,
    required this.days,
    required this.timeRange,
    this.hall = '',
    this.courseCode = '',
    this.instructor = '',
    this.enrolledCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBlue,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(courseName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark, fontFamily: 'Poppins')),
        ),
        if (courseCode.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(courseCode, style: const TextStyle(color: AppColors.textBlue, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textBlue),
        const SizedBox(width: 4),
        Text('$days  •  $timeRange', style: const TextStyle(color: AppColors.textBlue, fontSize: 13, fontFamily: 'Poppins')),
      ]),
      if (instructor.isNotEmpty) ...[
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textGray),
          const SizedBox(width: 4),
          Expanded(
            child: Text(instructor, style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ],
      if (hall.isNotEmpty) ...[
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.room_rounded, size: 13, color: AppColors.textGray),
          const SizedBox(width: 4),
          Text(hall, style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontFamily: 'Poppins')),
        ]),
      ],
      if (enrolledCount != null) ...[
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.people_alt_rounded, size: 13, color: AppColors.textGray),
          const SizedBox(width: 4),
          Text('$enrolledCount enrolled student${enrolledCount == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontFamily: 'Poppins')),
        ]),
      ],
    ]),
  );
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String message,
  String highlightWord = '',
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black26,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: AppColors.textDark, fontFamily: 'Poppins'),
              children: highlightWord.isEmpty
                  ? [TextSpan(text: message)]
                  : _buildHighlighted(message, highlightWord),
            ),
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(
                  fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(110, 46),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Yes', style: TextStyle(fontSize: 16)),
            ),
          ]),
        ]),
      ),
    ),
  );
}

List<TextSpan> _buildHighlighted(String text, String highlight) {
  final idx = text.indexOf(highlight);
  if (idx < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, idx)),
    TextSpan(text: highlight, style: const TextStyle(color: AppColors.textRed)),
    TextSpan(text: text.substring(idx + highlight.length)),
  ];
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  const AppSearchBar({super.key, required this.onChanged, this.hint = 'Search'});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(30),
    ),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGray, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

// ─── Snack helpers ────────────────────────────────────────────────────────────
void showSuccess(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

void showError(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}
