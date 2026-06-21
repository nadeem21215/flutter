// ─── User ─────────────────────────────────────────────────────────────────────
class UserModel {
  final String  name;
  final String  firebaseUid;
  final String  role;
  final String? studentCode;
  final String? level;
  final double? gpa;
  final int?    creditHours;
  final int?    warnings;
  final bool    hasRegistered;

  const UserModel({
    required this.name,
    required this.firebaseUid,
    required this.role,
    this.studentCode,
    this.level,
    this.gpa,
    this.creditHours,
    this.warnings,
    this.hasRegistered = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    name:          j['name']           as String,
    firebaseUid:   j['firebase_uid']   as String,
    role:          j['role']           as String,
    studentCode:   j['student_code']   as String?,
    level:         j['level']          as String?,
    gpa:           (j['gpa'] as num?)?.toDouble(),
    creditHours:   j['credit_hours']   as int?,
    warnings:      j['warnings']       as int?,
    hasRegistered: (j['has_registered'] as bool?) ?? false,
  );
}

// ─── Instructor (for admin instructor picker) ─────────────────────────────────
class InstructorModel {
  final String firebaseUid;
  final String name;

  const InstructorModel({required this.firebaseUid, required this.name});

  factory InstructorModel.fromJson(Map<String, dynamic> j) => InstructorModel(
    firebaseUid: (j['firebase_uid'] as String?) ?? '',
    name:        (j['name']         as String?) ?? '',
  );
}

// ─── Course ───────────────────────────────────────────────────────────────────
class CourseModel {
  final int    id;
  final String name;
  final String code;
  final int    creditHours;
  final bool   isEnrolled;
  final bool   isAvailable;
  final bool   isPassed;
  // [FIX #6] grade from history
  final String? grade;
  // [FIX #5 / #7] schedule & instructor
  final String  doctorName;
  final String  days;
  final String  timeFrom;
  final String  timeTo;
  final String  hall;
  // [FIX #7] course detail extras
  final String? prerequisiteCode;
  final String? prerequisiteName;
  final int?    targetYear;
  final int?    targetTerm;
  final bool    isElective;
  // Course description (editable by the instructor)
  final String  description;
  final String  doctorUid;

  const CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.creditHours,
    this.isEnrolled   = false,
    this.isAvailable  = true,
    this.isPassed     = true,
    this.grade,
    this.doctorName   = '',
    this.days         = '',
    this.timeFrom     = '',
    this.timeTo       = '',
    this.hall         = '',
    this.prerequisiteCode,
    this.prerequisiteName,
    this.targetYear,
    this.targetTerm,
    this.isElective   = false,
    this.description  = '',
    this.doctorUid    = '',
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
    id:               (j['id'] as int?) ?? 0,
    name:             j['name']         as String,
    code:             j['code']         as String,
    creditHours:      (j['credit_hours'] as num?)?.toInt() ?? 3,
    isEnrolled:       (j['is_enrolled']  as bool?) ?? false,
    isAvailable:      (j['is_available'] as bool?) ?? true,
    isPassed:         (j['is_passed']    as bool?) ?? true,
    grade:            j['grade']         as String?,
    doctorName:       (j['doctor_name']  as String?) ?? '',
    days:             (j['days']         as String?) ?? '',
    timeFrom:         (j['time_from']    as String?) ?? '',
    timeTo:           (j['time_to']      as String?) ?? '',
    hall:             (j['hall']         as String?) ?? '',
    prerequisiteCode: j['prerequisite_code'] as String?,
    prerequisiteName: j['prerequisite_name'] as String?,
    targetYear:       j['target_year']   as int?,
    targetTerm:       j['target_term']   as int?,
    isElective:       (j['is_elective']  as bool?) ?? false,
    description:      (j['description']  as String?) ?? '',
    doctorUid:        (j['doctor_uid']   as String?) ?? '',
  );

  CourseModel copyWith({bool? isEnrolled, bool? isAvailable}) => CourseModel(
    id:               id,
    name:             name,
    code:             code,
    creditHours:      creditHours,
    isEnrolled:       isEnrolled  ?? this.isEnrolled,
    isAvailable:      isAvailable ?? this.isAvailable,
    isPassed:         isPassed,
    grade:            grade,
    doctorName:       doctorName,
    days:             days,
    timeFrom:         timeFrom,
    timeTo:           timeTo,
    hall:             hall,
    prerequisiteCode: prerequisiteCode,
    prerequisiteName: prerequisiteName,
    targetYear:       targetYear,
    targetTerm:       targetTerm,
    isElective:       isElective,
    description:      description,
    doctorUid:        doctorUid,
  );

  String get timeRange => (timeFrom.isNotEmpty && timeTo.isNotEmpty)
      ? '$timeFrom – $timeTo'
      : '';
}

// ─── Schedule Item ────────────────────────────────────────────────────────────
class ScheduleItem {
  final String courseCode;
  final String courseName;
  final String days;
  final String timeFrom;
  final String timeTo;
  final String hall;
  final String doctorName;
  final int    enrolledCount;

  const ScheduleItem({
    required this.courseCode,
    required this.courseName,
    required this.days,
    required this.timeFrom,
    required this.timeTo,
    this.hall = '',
    this.doctorName = '',
    this.enrolledCount = 0,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
    courseCode:    (j['course_code'] as String?) ?? '',
    courseName:    j['course_name'] as String,
    days:          j['days']        as String,
    timeFrom:      j['time_from']   as String,
    timeTo:        j['time_to']     as String,
    hall:          (j['hall']        as String?) ?? '',
    doctorName:    (j['doctor_name'] as String?) ?? '',
    enrolledCount: (j['enrolled_count'] as int?) ?? 0,
  );

  String get timeRange => '$timeFrom – $timeTo';
}

// ─── Student ──────────────────────────────────────────────────────────────────
class StudentModel {
  final int     id;
  final String  name;
  final String  studentCode;
  final String? level;
  final double? gpa;
  final int?    creditHours;
  final int?    warnings;
  final List<CourseModel> courses;

  const StudentModel({
    required this.id,
    required this.name,
    required this.studentCode,
    this.level,
    this.gpa,
    this.creditHours,
    this.warnings,
    this.courses = const [],
  });

  factory StudentModel.fromJson(Map<String, dynamic> j) => StudentModel(
    id:          j['id']           as int,
    name:        j['name']         as String,
    studentCode: j['student_code'] as String,
    level:       j['level']        as String?,
    gpa:         (j['gpa'] as num?)?.toDouble(),
    creditHours: j['credit_hours'] as int?,
    warnings:    j['warnings']     as int?,
    courses: (j['courses'] as List<dynamic>?)
        ?.map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

// ─── Admin Stats ──────────────────────────────────────────────────────────────
class AdminStats {
  final int    studentCount;
  final int    instructorCount;
  final int    courseCount;
  final int    enrollmentCount;
  final int    registeredCount;
  final int    departmentCount;
  final int    suspendedCount;
  final String academicYear;

  const AdminStats({
    required this.studentCount,
    required this.instructorCount,
    required this.courseCount,
    required this.enrollmentCount,
    required this.registeredCount,
    required this.departmentCount,
    required this.suspendedCount,
    required this.academicYear,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    studentCount:    (j['student_count']    as int?) ?? 0,
    instructorCount: (j['instructor_count'] as int?) ?? 0,
    courseCount:     (j['course_count']     as int?) ?? 0,
    enrollmentCount: (j['enrollment_count'] as int?) ?? 0,
    registeredCount: (j['registered_count'] as int?) ?? 0,
    departmentCount: (j['department_count'] as int?) ?? 0,
    suspendedCount:  (j['suspended_count']  as int?) ?? 0,
    academicYear:    (j['academic_year']    as String?) ?? '',
  );
}

// ─── Assignment ───────────────────────────────────────────────────────────────
class AssignmentModel {
  final int    id;
  final String title;
  final String description;
  final String filename;
  final String courseCode;
  final String courseName;
  final String dueDate;
  final String uploadedAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.filename,
    required this.courseCode,
    required this.courseName,
    required this.dueDate,
    required this.uploadedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> j) => AssignmentModel(
    id:          (j['id']          as int?) ?? 0,
    title:       (j['title']       as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    filename:    (j['filename']    as String?) ?? '',
    courseCode:  (j['course_code'] as String?) ?? '',
    courseName:  (j['course_name'] as String?) ?? '',
    dueDate:     (j['due_date']    as String?) ?? '',
    uploadedAt:  (j['uploaded_at'] as String?) ?? '',
  );

  String get fileExtension => filename.contains('.')
      ? filename.split('.').last.toUpperCase()
      : 'FILE';
}

// ─── Submission ───────────────────────────────────────────────────────────────
class SubmissionModel {
  final int    id;
  final int    assignmentId;
  final String studentName;
  final String studentCode;
  final String filename;
  final String submittedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentName,
    required this.studentCode,
    required this.filename,
    required this.submittedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> j) => SubmissionModel(
    id:           (j['id']            as int?) ?? 0,
    assignmentId: (j['assignment_id'] as int?) ?? 0,
    studentName:  (j['student_name']  as String?) ?? '',
    studentCode:  (j['student_code']  as String?) ?? '',
    filename:     (j['filename']      as String?) ?? '',
    submittedAt:  (j['submitted_at']  as String?) ?? '',
  );

  String get fileExtension => filename.contains('.')
      ? filename.split('.').last.toUpperCase()
      : 'FILE';
}

// ─── Chat Message ─────────────────────────────────────────────────────────────
class ChatMessageModel {
  final String role;      // 'user' | 'assistant'
  final String content;
  final String createdAt;

  const ChatMessageModel({
    required this.role,
    required this.content,
    this.createdAt = '',
  });

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
    role:      (j['role']       as String?) ?? 'assistant',
    content:   (j['content']    as String?) ?? '',
    createdAt: (j['created_at'] as String?) ?? '',
  );
}

// ─── Registration Limits (credit-hour rules) ──────────────────────────────────
class RegistrationLimits {
  final double gpa;
  final int minHours;
  final int maxHours;

  const RegistrationLimits({
    required this.gpa,
    required this.minHours,
    required this.maxHours,
  });

  factory RegistrationLimits.fromJson(Map<String, dynamic> j) =>
      RegistrationLimits(
        gpa:      ((j['gpa'] as num?) ?? 0).toDouble(),
        minHours: (j['min_hours'] as int?) ?? 10,
        maxHours: (j['max_hours'] as int?) ?? 21,
      );
}
