import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static String? token;
  static Future<Map<String, dynamic>> createClinicalEntry({
  required int logbookId,
  required int logbookItemId,
  int? requirementId,
  required String activityDate,
  String? activityTime,
  required String facilityName,
  String? clinicalArea,
  String? activityDetails,
   
  }) 
  

 async {
    
    
  final response = await http.post(
    Uri.parse(
      '$baseUrl/student/logbooks/$logbookId/clinical-entries',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'logbook_item_id': logbookItemId,
      'logbook_item_requirement_id': requirementId,
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
    data['message'] ?? 'Unable to create clinical entry',
  );
}
  static Future<Map<String, dynamic>> getStudentLogbookDetails(
  int logbookId,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/student/logbooks/$logbookId'),
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
    data['message'] ?? 'Unable to load logbook details',
  );
}

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password, 
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'login': login,
        'password': password,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      token = data['token'];
      return data;
    }

    throw Exception(
      data['message'] ?? 'Login failed',
    );
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
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
      data['message'] ?? 'Unable to load user',
    );
  }

  static Future<List<dynamic>> getStudentLogbooks() async {
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
  static Future<List<dynamic>> getClinicalEntries(
  int logbookId,
) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/student/logbooks/$logbookId/clinical-entries',
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
    data['message'] ?? 'Unable to load clinical entries',
  );
}
static Future<Map<String, dynamic>> verifyClinicalEntry({
  required int entryId,
  required String supervisorName,
  String? facilityName,
  required String signaturePath,
}) async {
  final now = DateTime.now();

  final verificationTimestamp =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';

  final response = await http.post(
    Uri.parse(
      '$baseUrl/student/clinical-entries/$entryId/verify',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'supervisor_name': supervisorName,
      'facility_name': facilityName,

      // Temporary development value.
      // Real stylus signature storage comes next.
      'signature_path': signaturePath,

      'verification_timestamp': verificationTimestamp,

      // Do NOT pretend facial verification passed.
      'face_match_passed': null,
      'face_match_score': null,
      'face_capture_path': null,
      'time_check_passed': null,
    }),
  );

  final Map<String, dynamic> data =
      jsonDecode(response.body);

  if (response.statusCode == 201) {
    return data;
  }

  throw Exception(
    data['message'] ?? 'Unable to submit verification',
  );
}
}