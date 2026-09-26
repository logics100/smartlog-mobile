import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmartLogAuthenticationException
    implements Exception {
  final String message;

  SmartLogAuthenticationException(
    this.message,
  );

  @override
  String toString() => message;
}

class SmartLogNetworkException
    implements Exception {
  final String message;

  SmartLogNetworkException(
    this.message,
  );

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'SMARTLOG_API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static Uri get serverRootUri {
    final apiUri = Uri.parse(baseUrl);
    return apiUri.replace(
      path: '/',
      query: null,
      fragment: null,
    );
  }

  static String? token;

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================



  static Future<Map<String, dynamic>> login({
  required String login,
  required String password,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/login',
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Accept':
                'application/json',
          },
          body: jsonEncode({
            'login': login,
            'password': password,
          }),
        )
        .timeout(
          const Duration(
            seconds: 8,
          ),
        );

    Map<String, dynamic> data = {};

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        data =
            Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {
      // Handle unexpected non-JSON response.
    }

    if (response.statusCode == 200) {
      token =
          data['token']?.toString();

      return data;
    }

    // Laravel responded, so this is NOT
    // an offline/network failure.
    throw SmartLogAuthenticationException(
      data['message']?.toString() ??
          'Invalid DWU ID/email or password.',
    );
  } on SmartLogAuthenticationException {
    rethrow;
  } on SocketException catch (e) {
    throw SmartLogNetworkException(
      'Unable to reach SmartLog server: $e',
    );
  } on TimeoutException {
    throw SmartLogNetworkException(
      'SmartLog server connection timed out.',
    );
  } on http.ClientException catch (e) {
    throw SmartLogNetworkException(
      'Unable to connect to SmartLog server: $e',
    );
  }
}
  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(
            serverRootUri,
            headers: {
              'Accept': 'text/html',
            },
          )
          .timeout(
            const Duration(
              seconds: 5,
            ),
          );

      debugPrint(
        'SERVER CHECK STATUS: ${response.statusCode}',
      );

      return response.statusCode >= 200 &&
          response.statusCode < 500;
    } catch (e) {
      debugPrint(
        'SERVER CHECK ERROR: $e',
      );

      return false;
    }
  }
  static Future<void> logout() async {
    if (token == null) {
      return;
    }

    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    token = null;
  }

  // ===========================================================================
  // STUDENT
  // ===========================================================================

  static Future<List<dynamic>>
      getStudentLogbooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/logbooks'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['logbooks'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Unable to load logbooks',
    );
  }

  static Future<Map<String, dynamic>>
      getStudentLogbookDetails(
    int logbookId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/logbooks/$logbookId',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load logbook details',
    );
  }

  static Future<Map<String, dynamic>>
      getStudentLogbookProgress(
    int logbookId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/logbooks/$logbookId/progress',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load logbook progress',
    );
  }

  static Future<Map<String, dynamic>>
      createClinicalEntry({
    required int logbookId,
    required int logbookItemId,
    int? requirementId,
    required String activityDate,
    String? activityTime,
    required String facilityName,
    String? clinicalArea,
    String? activityDetails,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/student/logbooks/'
        '$logbookId/clinical-entries',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'logbook_item_id': logbookItemId,
        'logbook_item_requirement_id':
            requirementId,
        'activity_date': activityDate,
        'activity_time': activityTime,
        'facility_name': facilityName,
        'clinical_area': clinicalArea,
        'activity_details': activityDetails,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to create clinical entry',
    );
  }

  static Future<List<dynamic>>
      getClinicalEntries(
    int logbookId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/logbooks/'
        '$logbookId/clinical-entries',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['entries'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load clinical entries',
    );
  }

  static Future<List<dynamic>>
      searchClinicalSupervisors(
    String search,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/clinical-supervisors/search'
        '?search=${Uri.encodeQueryComponent(search)}',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['supervisors'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to search clinical supervisors',
    );
  }

  static Future<Map<String, dynamic>>
      registerSupervisorReferenceFace({
    required int supervisorId,
    required List<int> referenceFaceBytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/student/clinical-supervisors/'
        '$supervisorId/reference-face',
      ),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'reference_face',
        referenceFaceBytes,
        filename: 'reference_face.jpg',
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to register supervisor reference face',
    );
  }

  static Future<Map<String, dynamic>>
      verifyClinicalEntry({
    required int entryId,
    required int clinicalSupervisorId,
    required String supervisorName,
    String? facilityName,
    required List<int> signatureBytes,
    List<int>? faceBytes,
  }) async {
    final now = DateTime.now();

    final verificationTimestamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/student/'
        'clinical-entries/$entryId/verify',
      ),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['supervisor_name'] =
        supervisorName;

    request.fields['clinical_supervisor_id'] =
        clinicalSupervisorId.toString();

    if (facilityName != null &&
        facilityName.isNotEmpty) {
      request.fields['facility_name'] =
          facilityName;
    }

    request.fields['verification_timestamp'] =
        verificationTimestamp;

    request.files.add(
      http.MultipartFile.fromBytes(
        'signature',
        signatureBytes,
        filename: 'signature.png',
      ),
    );

    if (faceBytes != null &&
        faceBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'face_capture',
          faceBytes,
          filename: 'supervisor_face.jpg',
        ),
      );
    }

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to submit verification',
    );
  }
    // ===========================================================================
  // STUDENT - ATTENDANCE
  // ===========================================================================

  static Future<List<dynamic>>
      getStudentAttendanceRecords(
    int logbookId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/logbooks/$logbookId/attendance',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['attendance_records'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load attendance records',
    );
  }

  static Future<Map<String, dynamic>>
      createStudentAttendance({
    required int logbookId,
    required String attendanceDate,
    required String facilityName,
    required String clinicalUnit,
    required String startTime,
    required String finishTime,
  }) 
  
  async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/student/logbooks/$logbookId/attendance',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'attendance_date': attendanceDate,
        'facility_name': facilityName.trim(),
        'clinical_unit': clinicalUnit.trim(),
        'start_time': startTime,
        'finish_time': finishTime,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    String message =
        data['message'] ??
            'Unable to create attendance record';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
      }
    }

    throw Exception(message);
  }
  static Future<Map<String, dynamic>>
    verifyStudentAttendance({
  required int attendanceId,
  required int clinicalSupervisorId,
  required String supervisorName,
  String? facilityName,
  required List<int> signatureBytes,
  List<int>? faceBytes,
}) async {
  final now = DateTime.now();

  final verificationTimestamp =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';

  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
      '$baseUrl/student/attendance/$attendanceId/verify',
    ),
  );

  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  request.fields['clinical_supervisor_id'] =
      clinicalSupervisorId.toString();

  request.fields['supervisor_name'] =
      supervisorName.trim();

  if (facilityName != null &&
      facilityName.trim().isNotEmpty) {
    request.fields['facility_name'] =
        facilityName.trim();
  }

  request.fields['verification_timestamp'] =
      verificationTimestamp;

  request.files.add(
    http.MultipartFile.fromBytes(
      'signature',
      signatureBytes,
      filename: 'attendance_signature.png',
    ),
  );

  if (faceBytes != null && faceBytes.isNotEmpty) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'face_capture',
        faceBytes,
        filename: 'attendance_supervisor_face.jpg',
      ),
    );
  }

  final streamedResponse =
      await request.send();

  final response =
      await http.Response.fromStream(
    streamedResponse,
  );

  Map<String, dynamic> data = {};

  if (response.body.isNotEmpty) {
    data = Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return data;
  }

  String message =
      data['message'] ??
          'Unable to verify attendance';

  if (data['errors'] is Map) {
    final errors =
        Map<String, dynamic>.from(
      data['errors'],
    );

    if (errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List &&
          firstError.isNotEmpty) {
        message = firstError.first.toString();
      }
    }
  }

  throw Exception(message);
}

  // ===========================================================================
  // LECTURER
  // ===========================================================================

  static Future<Map<String, dynamic>> getLecturerDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lecturer/dashboard'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Unable to load lecturer dashboard',
    );
  }
  static Future<List<dynamic>>
      getLecturerPendingVerifications() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/verifications/pending',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['verifications'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load pending verifications',
    );
  }

  static Future<Map<String, dynamic>>
      getLecturerVerificationDetails(
    int verificationId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/verifications/'
        '$verificationId',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load verification details',
    );
  }

  static Future<Map<String, dynamic>>
      reviewLecturerVerification({
    required int verificationId,
    required String decision,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/lecturer/verifications/'
        '$verificationId/review',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'decision': decision,
        'comment': comment,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to review verification',
    );
  }

  static Future<List<dynamic>>
      getLecturerUnits() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/units',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['units'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load lecturer units',
    );
  }

  static Future<List<dynamic>>
      getLecturerUnitStudents(
    int unitId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/units/$unitId/students',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['students'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load students for this unit',
    );
  }

  static Future<List<dynamic>>
      searchStudentsForUnit({
    required int unitId,
    required String search,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/units/$unitId/students/search'
        '?search=${Uri.encodeQueryComponent(search)}',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['students'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to search students',
    );
  }

  static Future<Map<String, dynamic>>
      enrollStudentInUnit({
    required int unitId,
    required int studentId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/lecturer/units/$unitId/enroll',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'student_id': studentId,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to enroll student',
    );
  }

  static Future<Map<String, dynamic>>
      getLecturerStudentProgress({
    required int unitId,
    required int studentId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/units/'
        '$unitId/students/$studentId/progress',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load student clinical progress',
    );
  }

  static Future<Map<String, dynamic>>
      getLecturerClinicalEntryDetails({
    required int unitId,
    required int studentId,
    required int entryId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/lecturer/units/'
        '$unitId/students/$studentId/'
        'entries/$entryId',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load clinical entry details',
    );
  }

  // ===========================================================================
  // HOD - READ ONLY
  // ===========================================================================

  static Future<Map<String, dynamic>>
      getHodDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/hod/dashboard'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load HOD dashboard',
    );
  }

  static Future<List<dynamic>>
      getHodStudents({
    String search = '',
    int? yearLevelId,
  }) async {
    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (yearLevelId != null) {
      queryParameters['year_level_id'] =
          yearLevelId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/hod/students',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['students'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load department students',
    );
  }

  static Future<Map<String, dynamic>>
      getHodStudentProgress(
    int studentId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/hod/students/$studentId/progress',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load student progress',
    );
  }

  static Future<List<dynamic>>
      getHodUnits({
    int? yearLevelId,
  }) async {
    final queryParameters = <String, String>{};

    if (yearLevelId != null) {
      queryParameters['year_level_id'] =
          yearLevelId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/hod/units',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['units'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load department units',
    );
  }

  static Future<Map<String, dynamic>>
      getHodUnitProgress(
    int unitId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/hod/units/$unitId/progress',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load unit progress',
    );
  }

  static Future<List<dynamic>>
      getHodYearLevels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/hod/year-levels'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['year_levels'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load department year levels',
    );
  }

  static Future<List<dynamic>>
      getHodLecturers({
    String search = '',
  }) async {
    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/hod/lecturers',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['lecturers'] ?? [];
    }

    throw Exception(
      data['message'] ??
          'Unable to load department lecturers',
    );
  }

  static Future<Map<String, dynamic>>
      getHodLecturerProgress(
    int lecturerId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/hod/lecturers/'
        '$lecturerId/progress',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load lecturer progress',
    );
  }

  // ===========================================================================
  // ICT ADMIN - SYSTEM MANAGEMENT
  // ===========================================================================

  static Future<Map<String, dynamic>>
      getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load ICT Admin dashboard',
    );
  }

  // ===========================================================================
  // ICT ADMIN - USER MANAGEMENT
  // ===========================================================================

  static Future<Map<String, dynamic>>
      getAdminUsers({
    String search = '',
    String? role,
    int? departmentId,
    String? status,
  }) async {
    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (role != null &&
        role.trim().isNotEmpty) {
      queryParameters['role'] = role.trim();
    }

    if (departmentId != null) {
      queryParameters['department_id'] =
          departmentId.toString();
    }

    if (status != null &&
        status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/admin/users',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load ICT Admin users',
    );
  }


  static Future<Map<String, dynamic>>
      createAdminUser({
    required String dwuId,
    required String name,
    required String email,
    String? phone,
    required String role,
    int? departmentId,
    int? yearLevelId,
    required String password,
    required String passwordConfirmation,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'dwu_id': dwuId.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim().isEmpty == true
            ? null
            : phone?.trim(),
        'role': role,
        'department_id': departmentId,
        'year_level_id': yearLevelId,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'is_active': isActive,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    String message =
        data['message'] ?? 'Unable to create SmartLog user';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(data['errors']);

      if (errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
      }
    }

    throw Exception(message);
  }
    static Future<Map<String, dynamic>>
      updateAdminUser({
    required int userId,
    required String dwuId,
    required String name,
    required String email,
    String? phone,
    required String role,
    int? departmentId,
    int? yearLevelId,
    String? password,
    String? passwordConfirmation,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'dwu_id': dwuId.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone?.trim().isEmpty == true
          ? null
          : phone?.trim(),
      'role': role,
      'department_id': departmentId,
      'year_level_id': yearLevelId,
      'is_active': isActive,
    };

    /*
    |--------------------------------------------------------------------------
    | Optional Password
    |--------------------------------------------------------------------------
    |
    | Only send the password fields when the ICT Admin actually enters
    | a new password. Leaving them blank keeps the user's current password.
    |
    */

    if (password != null &&
        password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] =
          passwordConfirmation ?? '';
    }

    final response = await http.put(
      Uri.parse(
        '$baseUrl/admin/users/$userId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 200) {
      return data;
    }

    /*
    |--------------------------------------------------------------------------
    | Laravel Validation Errors
    |--------------------------------------------------------------------------
    */

    String message =
        data['message'] ??
        'Unable to update SmartLog user';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError =
            errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message =
              firstError.first.toString();
        } else if (firstError != null) {
          message =
              firstError.toString();
        }
      }
    }

    throw Exception(message);
  }
    // ===========================================================================
  // ICT ADMIN - DEPARTMENT MANAGEMENT
  // ===========================================================================

  static Future<Map<String, dynamic>>
      getAdminDepartments({
    String search = '',
    String? status,
  }) async {
    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (status != null &&
        status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/admin/departments',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load SmartLog departments',
    );
  }

  static Future<Map<String, dynamic>>
      createAdminDepartment({
    required String departmentCode,
    required String departmentName,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/admin/departments',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'department_code':
            departmentCode.trim(),
        'department_name':
            departmentName.trim(),
        'is_active': isActive,
      }),
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 201) {
      return data;
    }

    String message =
        data['message'] ??
        'Unable to create SmartLog department';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError =
            errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message =
              firstError.first.toString();
        } else if (firstError != null) {
          message =
              firstError.toString();
        }
      }
    }

    throw Exception(message);
  }

  static Future<Map<String, dynamic>>
      updateAdminDepartment({
    required int departmentId,
    required String departmentCode,
    required String departmentName,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/admin/departments/'
        '$departmentId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'department_code':
            departmentCode.trim(),
        'department_name':
            departmentName.trim(),
        'is_active': isActive,
      }),
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 200) {
      return data;
    }

    String message =
        data['message'] ??
        'Unable to update SmartLog department';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError =
            errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message =
              firstError.first.toString();
        } else if (firstError != null) {
          message =
              firstError.toString();
        }
      }
    }

    throw Exception(message);
  }
  // ===========================================================================
  // ICT ADMIN - UNIT MANAGEMENT
  // ===========================================================================

  static Future<Map<String, dynamic>>
      getAdminUnits({
    String search = '',
    int? departmentId,
    int? yearLevelId,
    int? semesterId,
    String? status,
    String? requiresLogbook,
  }) async {
    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (departmentId != null) {
      queryParameters['department_id'] =
          departmentId.toString();
    }

    if (yearLevelId != null) {
      queryParameters['year_level_id'] =
          yearLevelId.toString();
    }

    if (semesterId != null) {
      queryParameters['semester_id'] =
          semesterId.toString();
    }

    if (status != null &&
        status.trim().isNotEmpty) {
      queryParameters['status'] =
          status.trim();
    }

    if (requiresLogbook != null &&
        requiresLogbook.trim().isNotEmpty) {
      queryParameters['requires_logbook'] =
          requiresLogbook.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/admin/units',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ??
          'Unable to load SmartLog units',
    );
  }

  static Future<Map<String, dynamic>>
      createAdminUnit({
    required String unitCode,
    required String unitName,
    required int departmentId,
    required int yearLevelId,
    required int semesterId,
    required bool requiresLogbook,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/admin/units',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'unit_code': unitCode.trim(),
        'unit_name': unitName.trim(),
        'department_id': departmentId,
        'year_level_id': yearLevelId,
        'semester_id': semesterId,
        'requires_logbook': requiresLogbook,
        'is_active': isActive,
      }),
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 201) {
      return data;
    }

    String message =
        data['message'] ??
        'Unable to create SmartLog unit';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError =
            errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message =
              firstError.first.toString();
        } else if (firstError != null) {
          message =
              firstError.toString();
        }
      }
    }

    throw Exception(message);
  }

  static Future<Map<String, dynamic>>
      updateAdminUnit({
    required int unitId,
    required String unitCode,
    required String unitName,
    required int departmentId,
    required int yearLevelId,
    required int semesterId,
    required bool requiresLogbook,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/admin/units/$unitId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'unit_code': unitCode.trim(),
        'unit_name': unitName.trim(),
        'department_id': departmentId,
        'year_level_id': yearLevelId,
        'semester_id': semesterId,
        'requires_logbook': requiresLogbook,
        'is_active': isActive,
      }),
    );

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
      } catch (_) {
        throw Exception(
          'Invalid response from SmartLog server.',
        );
      }
    }

    if (response.statusCode == 200) {
      return data;
    }

    String message =
        data['message'] ??
        'Unable to update SmartLog unit';

    if (data['errors'] is Map) {
      final errors =
          Map<String, dynamic>.from(
        data['errors'],
      );

      if (errors.isNotEmpty) {
        final firstError =
            errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          message =
              firstError.first.toString();
        } else if (firstError != null) {
          message =
              firstError.toString();
        }
      }
    }

    throw Exception(message);
  }
}
