import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/network/http_exception.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();
  static const _timeout = Duration(seconds: 15);
  Map<String, String> get _headers =>
      {'Content-Type': 'application/json', 'Accept': 'application/json'};

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    String detail = 'Server error: ${res.statusCode}';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['detail'] != null) {
        detail = body['detail'].toString();
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 401:
        throw const HttpException(
            message: 'Incorrect username or password', statusCode: 401);
      case 404:
        throw HttpException(message: detail, statusCode: 404);
      case 409:
        throw const HttpException(
            message: 'Already registered', statusCode: 409);
      default:
        throw HttpException(message: detail, statusCode: res.statusCode);
    }
  }

  Future<UserModel> login(
      {required String username, required String password}) async {
    try {
      final loginRes = await http
          .post(
            Uri.parse(
                '${AppConstants.baseUrl}/login?student_code=$username&password=$password'),
            headers: _headers,
          )
          .timeout(_timeout);
      final d = _handle(loginRes) as Map<String, dynamic>;
      final uid = d['firebase_uid'] as String;
      final role = d['role'] as String;
      final name = d['name'] as String? ?? '';
      if (role == 'student') {
        final profileRes = await http
            .get(Uri.parse('${AppConstants.baseUrl}/student/profile/$uid'),
                headers: _headers)
            .timeout(_timeout);
        final p = _handle(profileRes) as Map<String, dynamic>;
        return UserModel(
          name: p['name'] as String? ?? name,
          firebaseUid: uid,
          role: role,
          studentCode: username,
          level: 'Year ${p['current_year']} - Term ${p['current_term']}',
          gpa: (p['gpa'] as num?)?.toDouble(),
          creditHours: (p['total_passed_credit_hours'] as num?)?.toInt() ?? 0,
          warnings: (p['warnings'] as num?)?.toInt() ?? 0,
          hasRegistered: (p['has_registered'] as bool?) ?? false,
        );
      }
      return UserModel(name: name, firebaseUid: uid, role: role);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Cannot connect to server.\n$e');
    }
  }

  // [FIX #5] getSchedule calls the real /student/schedule/{uid} endpoint
  Future<List<ScheduleItem>> getSchedule(
      {required String firebaseUid, bool isDoctor = false}) async {
    try {
      final path = isDoctor
          ? '${AppConstants.baseUrl}/doctor/schedule/$firebaseUid'
          : '${AppConstants.baseUrl}/student/schedule/$firebaseUid';
      final res =
          await http.get(Uri.parse(path), headers: _headers).timeout(_timeout);
      final data = _handle(res);
      final list = (data is List) ? data : [];
      return list
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } catch (_) {
      return [];
    }
  }

  Future<List<CourseModel>> getCourses({required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/courses?firebase_uid=$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      return (_handle(res) as List)
          .map((e) => CourseModel.fromJson(e))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load courses: $e');
    }
  }

  Future<List<CourseModel>> getStudentRegisteredCourses(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse('${AppConstants.baseUrl}/student/courses/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      final list = data['registered_courses'] as List? ?? [];
      return list
          .map((e) => CourseModel(
                id: 0,
                name: e['name'] as String,
                code: e['code'] as String,
                creditHours: (e['credit_hours'] as num?)?.toInt() ?? 3,
                isEnrolled: true,
                isAvailable: true,
                doctorName: (e['doctor_name'] as String?) ?? '',
                days: (e['days'] as String?) ?? '',
                timeFrom: (e['time_from'] as String?) ?? '',
                timeTo: (e['time_to'] as String?) ?? '',
                hall: (e['hall'] as String?) ?? '',
              ))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load courses: $e');
    }
  }

  Future<RegistrationLimits> getRegistrationLimits(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/registration-limits/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      return RegistrationLimits.fromJson(
          _handle(res) as Map<String, dynamic>);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load limits: $e');
    }
  }

  Future<void> enrollCourseByCodes(
      {required String firebaseUid, required List<String> courseCodes}) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/register-courses'),
            headers: _headers,
            body: jsonEncode(
                {'firebase_uid': firebaseUid, 'course_codes': courseCodes}),
          )
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Enrollment failed: $e');
    }
  }

  Future<bool> checkHasRegistered({required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse('${AppConstants.baseUrl}/student/profile/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      return (data['has_registered'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // [FIX #6] getCompletedCourses — includes grade from history
  Future<List<CourseModel>> getCompletedCourses(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse('${AppConstants.baseUrl}/student/history/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      final history = data['history'] as List? ?? [];
      return history
          .map((e) => CourseModel(
                id: 0,
                name: e['course_name'] as String,
                code: e['course_code'] as String,
                creditHours: (e['credit_hours'] as num?)?.toInt() ?? 3,
                isPassed: e['status'] == 'passed',
                grade: e['grade'] as String?,
              ))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load completed courses: $e');
    }
  }

  // [FIX #7] New: fetch full course detail including instructor & schedule
  Future<CourseModel> getCourseDetail({required String courseCode}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/course/$courseCode'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      return CourseModel(
        id: 0,
        name: data['name'] as String,
        code: data['code'] as String,
        creditHours: (data['credit_hours'] as num?)?.toInt() ?? 3,
        doctorName: (data['doctor_name'] as String?) ?? '',
        days: (data['days'] as String?) ?? '',
        timeFrom: (data['time_from'] as String?) ?? '',
        timeTo: (data['time_to'] as String?) ?? '',
        hall: (data['hall'] as String?) ?? '',
        prerequisiteCode: data['prerequisite_code'] as String?,
        prerequisiteName: data['prerequisite_name'] as String?,
        targetYear: data['target_year'] as int?,
        targetTerm: data['target_term'] as int?,
        isElective: (data['is_elective'] as bool?) ?? false,
        description: (data['description'] as String?) ?? '',
        doctorUid: (data['doctor_uid'] as String?) ?? '',
      );
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load course detail: $e');
    }
  }

  Future<List<CourseModel>> getDoctorCourses(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/doctor/courses/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      final list = data['courses'] as List? ?? [];
      return list
          .map((e) => CourseModel(
                id: 0,
                name: e['name'] as String,
                code: e['code'] as String,
                creditHours: (e['credit_hours'] as num?)?.toInt() ?? 3,
                isAvailable: true,
                days: (e['days'] as String?) ?? '',
                timeFrom: (e['time_from'] as String?) ?? '',
                timeTo: (e['time_to'] as String?) ?? '',
                hall: (e['hall'] as String?) ?? '',
                description: (e['description'] as String?) ?? '',
                doctorUid: (e['doctor_uid'] as String?) ?? '',
                targetYear: e['target_year'] as int?,
                targetTerm: e['target_term'] as int?,
                isElective: (e['is_elective'] as bool?) ?? false,
                prerequisiteCode: e['prerequisite_code'] as String?,
              ))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load doctor courses: $e');
    }
  }

  // [FIX #5] Doctor schedule
  Future<List<ScheduleItem>> getDoctorSchedule(
      {required String firebaseUid}) async {
    return getSchedule(firebaseUid: firebaseUid, isDoctor: true);
  }

  Future<List<StudentModel>> getDoctorStudents(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/students'), headers: _headers)
          .timeout(_timeout);
      return (_handle(res) as List)
          .map((e) => StudentModel.fromJson(e))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load students: $e');
    }
  }

  // [FIX #8] getAdminStats — now maps the full extended stats
  Future<AdminStats> getAdminStats() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/stats'), headers: _headers)
          .timeout(_timeout);
      return AdminStats.fromJson(_handle(res) as Map<String, dynamic>);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load stats: $e');
    }
  }

  Future<List<StudentModel>> getAllStudents() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/students'), headers: _headers)
          .timeout(_timeout);
      return (_handle(res) as List)
          .map((e) => StudentModel.fromJson(e))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load students: $e');
    }
  }

  Future<StudentModel> getStudentDetail({required int studentId}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/students/$studentId'),
              headers: _headers)
          .timeout(_timeout);
      return StudentModel.fromJson(_handle(res) as Map<String, dynamic>);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load student: $e');
    }
  }

  // ─── Instructors (admin management) ────────────────────────────────────────

  Future<List<InstructorModel>> getInstructors() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/instructors'),
              headers: _headers)
          .timeout(_timeout);
      return (_handle(res) as List)
          .map((e) => InstructorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load instructors: $e');
    }
  }

  /// Fetch all courses assigned to an instructor (doctor_uid).
  Future<Map<String, dynamic>> getInstructorWithCourses(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/doctor/courses/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      final list = data['courses'] as List? ?? [];
      final courses = list
          .map((e) => CourseModel(
                id: 0,
                name: e['name'] as String,
                code: e['code'] as String,
                creditHours: (e['credit_hours'] as num?)?.toInt() ?? 3,
                days: (e['days'] as String?) ?? '',
                timeFrom: (e['time_from'] as String?) ?? '',
                timeTo: (e['time_to'] as String?) ?? '',
                hall: (e['hall'] as String?) ?? '',
                description: (e['description'] as String?) ?? '',
                doctorUid: firebaseUid,
                targetYear: e['target_year'] as int?,
                targetTerm: e['target_term'] as int?,
                isElective: (e['is_elective'] as bool?) ?? false,
                prerequisiteCode: e['prerequisite_code'] as String?,
              ))
          .toList();
      return {
        'courses': courses,
        'total': data['total_courses'] ?? courses.length,
        'name': (data['doctor_name'] as String?) ?? '',
      };
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load instructor courses: $e');
    }
  }

  /// Assign a course to an instructor by updating the course's doctor_uid.
  Future<void> assignCourseToInstructor(
      {required String courseCode,
      required String instructorUid}) async {
    await updateCourse(code: courseCode, doctorUid: instructorUid);
  }

  /// Remove a course from an instructor by clearing the course's doctor_uid.
  Future<void> removeCourseFromInstructor(
      {required String courseCode}) async {
    await updateCourse(code: courseCode, doctorUid: '');
  }

  Future<List<CourseModel>> getAllCourses() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/curriculum'),
              headers: _headers)
          .timeout(_timeout);
      final data = _handle(res) as Map<String, dynamic>;
      final curriculum = data['curriculum'] as Map<String, dynamic>;
      final list = <CourseModel>[];
      for (final term in curriculum.values) {
        for (final c in term as List) {
          list.add(CourseModel(
            id: 0,
            name: c['name'] as String,
            code: c['code'] as String,
            creditHours: (c['credit_hours'] as num?)?.toInt() ?? 3,
            doctorName: (c['doctor_name'] as String?) ?? '',
            days: (c['days'] as String?) ?? '',
            timeFrom: (c['time_from'] as String?) ?? '',
            timeTo: (c['time_to'] as String?) ?? '',
            hall: (c['hall'] as String?) ?? '',
            targetYear: (c['target_year'] as int?),
            targetTerm: (c['target_term'] as int?),
            isElective: (c['is_elective'] as bool?) ?? false,
            prerequisiteCode: c['prerequisite_code'] as String?,
            doctorUid: (c['doctor_uid'] as String?) ?? '',
          ));
        }
      }
      return list;
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load courses: $e');
    }
  }

  Future<void> addCourse({
    required String name,
    required String code,
    required int creditHours,
    int targetYear = 1,
    int termInYear = 1,
    bool isElective = false,
    String? prerequisiteCode,
    String? doctorUid,
    String? description,
    String? hall,
    String? days,
    String? timeFrom,
    String? timeTo,
  }) async {
    try {
      final res = await http
          .post(Uri.parse('${AppConstants.baseUrl}/courses'),
              headers: _headers,
              body: jsonEncode({
                'name': name,
                'code': code,
                'credit_hours': creditHours,
                'target_year': targetYear,
                'term_in_year': termInYear,
                'is_elective': isElective,
                if (prerequisiteCode != null && prerequisiteCode.isNotEmpty)
                  'prerequisite_code': prerequisiteCode,
                if (doctorUid != null && doctorUid.isNotEmpty)
                  'doctor_uid': doctorUid,
                if (description != null && description.isNotEmpty)
                  'description': description,
                if (hall != null && hall.isNotEmpty) 'hall': hall,
                if (days != null && days.isNotEmpty) 'days': days,
                if (timeFrom != null && timeFrom.isNotEmpty)
                  'time_from': timeFrom,
                if (timeTo != null && timeTo.isNotEmpty) 'time_to': timeTo,
              }))
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to add course: $e');
    }
  }

  Future<void> updateCourse({
    required String code,
    String? name,
    int? creditHours,
    int? targetYear,
    int? termInYear,
    bool? isElective,
    String? prerequisiteCode, // '' clears it
    String? doctorUid, // '' clears it
    String? description,
    String? hall,
    String? days,
    String? timeFrom,
    String? timeTo,
  }) async {
    try {
      final res = await http
          .put(Uri.parse('${AppConstants.baseUrl}/courses/$code'),
              headers: _headers,
              body: jsonEncode({
                if (name != null) 'name': name,
                if (creditHours != null) 'credit_hours': creditHours,
                if (targetYear != null) 'target_year': targetYear,
                if (termInYear != null) 'term_in_year': termInYear,
                if (isElective != null) 'is_elective': isElective,
                if (prerequisiteCode != null)
                  'prerequisite_code': prerequisiteCode,
                if (doctorUid != null) 'doctor_uid': doctorUid,
                if (description != null) 'description': description,
                if (hall != null) 'hall': hall,
                if (days != null) 'days': days,
                if (timeFrom != null) 'time_from': timeFrom,
                if (timeTo != null) 'time_to': timeTo,
              }))
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to update course: $e');
    }
  }

  Future<void> removeCourse({required int courseId, String? courseCode}) async {
    try {
      if (courseCode == null || courseCode.isEmpty) {
        throw HttpException(message: 'Course code is required for deletion.');
      }
      final res = await http
          .delete(
              Uri.parse(
                  '${AppConstants.baseUrl}/courses/${Uri.encodeComponent(courseCode)}'),
              headers: _headers)
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to remove course: $e');
    }
  }

  Future<void> addCourseToStudent(
      {required int studentId,
      required int courseId,
      String? courseCode}) async {
    try {
      final res = await http
          .post(Uri.parse('${AppConstants.baseUrl}/add_course'),
              headers: _headers,
              body: jsonEncode(
                  {'student_id': studentId, 'course_code': courseCode ?? ''}))
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to add course: $e');
    }
  }

  Future<void> removeCourseFromStudent(
      {required int studentId,
      required int courseId,
      String? courseCode}) async {
    try {
      final res = await http
          .post(Uri.parse('${AppConstants.baseUrl}/remove_course'),
              headers: _headers,
              body: jsonEncode(
                  {'student_id': studentId, 'course_code': courseCode ?? ''}))
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to remove course: $e');
    }
  }

  // ─── Assignments ────────────────────────────────────────────────────────────

  Future<List<AssignmentModel>> getStudentAssignments(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/assignments/student/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final list = _handle(res) as List;
      return list
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load assignments: $e');
    }
  }

  Future<List<AssignmentModel>> getDoctorAssignments(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/assignments/doctor/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final list = _handle(res) as List;
      return list
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load assignments: $e');
    }
  }

  Future<void> uploadAssignment({
    required String doctorUid,
    required String courseCode,
    required String title,
    required String description,
    required String dueDate,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/assignments/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['doctor_uid'] = doctorUid
        ..fields['course_code'] = courseCode
        ..fields['title'] = title
        ..fields['description'] = description
        ..fields['due_date'] = dueDate
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: filename));
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Upload failed: $e');
    }
  }

  Future<void> deleteAssignment(
      {required int assignmentId, required String doctorUid}) async {
    try {
      final res = await http
          .delete(
              Uri.parse(
                  '${AppConstants.baseUrl}/assignments/$assignmentId?doctor_uid=$doctorUid'),
              headers: _headers)
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Delete failed: $e');
    }
  }

  String getAssignmentDownloadUrl(int assignmentId) =>
      '${AppConstants.baseUrl}/assignments/download/$assignmentId';

  // ─── Submissions ────────────────────────────────────────────────────────────

  Future<void> uploadSubmission({
    required String studentUid,
    required int assignmentId,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/submissions/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['student_uid'] = studentUid
        ..fields['assignment_id'] = assignmentId.toString()
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: filename));
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Upload failed: $e');
    }
  }

  Future<List<SubmissionModel>> getStudentSubmissions(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/submissions/student/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final list = _handle(res) as List;
      return list
          .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load submissions: $e');
    }
  }

  Future<List<SubmissionModel>> getAssignmentSubmissions(
      {required int assignmentId, required String doctorUid}) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '${AppConstants.baseUrl}/submissions/assignment/$assignmentId?doctor_uid=$doctorUid'),
              headers: _headers)
          .timeout(_timeout);
      final list = _handle(res) as List;
      return list
          .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load submissions: $e');
    }
  }

  String getSubmissionDownloadUrl(int submissionId) =>
      '${AppConstants.baseUrl}/submissions/download/$submissionId';

  // ─── Notifications ──────────────────────────────────────────────────────────

  Future<void> registerFcmToken(
      {required String firebaseUid, required String token}) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/notifications/register-token'),
            headers: _headers,
            body: jsonEncode(
                {'firebase_uid': firebaseUid, 'fcm_token': token}),
          )
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Token registration failed: $e');
    }
  }

  // ─── AI Chat ────────────────────────────────────────────────────────────────

  Future<String> sendChatMessage(
      {required String firebaseUid, required String message}) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/chat/message'),
            headers: _headers,
            body: jsonEncode({'user_id': firebaseUid, 'message': message}),
          )
          .timeout(const Duration(seconds: 45)); // AI responses can be slow
      final data = _handle(res) as Map<String, dynamic>;
      return (data['ai_response'] as String?) ?? '';
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to send message: $e');
    }
  }

  Future<List<ChatMessageModel>> getChatHistory(
      {required String firebaseUid}) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/chat/history/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      final list = _handle(res) as List;
      return list
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to load chat history: $e');
    }
  }

  Future<void> clearChatHistory({required String firebaseUid}) async {
    try {
      final res = await http
          .delete(
              Uri.parse('${AppConstants.baseUrl}/chat/history/$firebaseUid'),
              headers: _headers)
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to clear chat: $e');
    }
  }

  // ─── Course Description ─────────────────────────────────────────────────────

  Future<void> updateCourseDescription({
    required String courseCode,
    required String doctorUid,
    required String description,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('${AppConstants.baseUrl}/course/$courseCode/description'),
            headers: _headers,
            body: jsonEncode(
                {'doctor_uid': doctorUid, 'description': description}),
          )
          .timeout(_timeout);
      _handle(res);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException(message: 'Failed to update description: $e');
    }
  }
}
