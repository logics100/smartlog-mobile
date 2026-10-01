import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class LecturerLogbookApi {
  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${ApiService.token}',
  };

  static dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    String message = 'Request failed (${response.statusCode}).';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    }
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    }
    throw Exception(message);
  }

  static Future<List<dynamic>> getLogbooks() async {
    final r = await http.get(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks'),
      headers: _headers,
    );
    final d = _decode(r);
    return d is Map ? (d['logbooks'] as List? ?? []) : [];
  }

  static Future<Map<String, dynamic>> getLogbook(int id) async {
    final r = await http.get(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks/$id'),
      headers: _headers,
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> createLogbook({
    required int unitId,
    required String name,
    String? description,
    required double minimum,
    required bool active,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks'),
      headers: _headers,
      body: jsonEncode({
        'unit_id': unitId,
        'template_name': name,
        'description': description,
        'minimum_completion_percentage': minimum,
        'is_active': active,
      }),
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> updateLogbook({
    required int id,
    required String name,
    String? description,
    required double minimum,
    required bool active,
  }) async {
    final r = await http.put(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks/$id'),
      headers: _headers,
      body: jsonEncode({
        'template_name': name,
        'description': description,
        'minimum_completion_percentage': minimum,
        'is_active': active,
      }),
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> assign(int id) async {
    final r = await http.post(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks/$id/assign'),
      headers: _headers,
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> addSection({
    required int templateId,
    required String title,
    required String type,
    String? instructions,
    required int order,
    required bool verify,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiService.baseUrl}/lecturer/logbooks/$templateId/sections'),
      headers: _headers,
      body: jsonEncode({
        'section_title': title,
        'section_type': type,
        'instructions': instructions,
        'display_order': order,
        'requires_supervisor_verification': verify,
      }),
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> addItem({
    required int templateId,
    required int sectionId,
    required String name,
    String? description,
    String? level,
    required int count,
    required bool verify,
    required int order,
    required bool active,
  }) async {
    final r = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/lecturer/logbooks/$templateId/sections/$sectionId/items',
      ),
      headers: _headers,
      body: jsonEncode({
        'item_name': name,
        'item_description': description,
        'required_level': level,
        'required_count': count,
        'requires_supervisor_verification': verify,
        'display_order': order,
        'is_active': active,
      }),
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  static Future<Map<String, dynamic>> addRequirement({
    required int templateId,
    required int itemId,
    required String code,
    required String label,
    required bool simulation,
  }) async {
    final r = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/lecturer/logbooks/$templateId/items/$itemId/requirements',
      ),
      headers: _headers,
      body: jsonEncode({
        'requirement_code': code,
        'requirement_label': label,
        'is_simulation': simulation,
      }),
    );
    return Map<String, dynamic>.from(_decode(r) as Map);
  }
}
