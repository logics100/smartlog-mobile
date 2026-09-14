import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineAuthService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _userKey =
      'smartlog_offline_student_user';

  static const String _identifierKey =
      'smartlog_offline_student_identifier';

  static const String _passwordKey =
      'smartlog_offline_student_password';

  static Future<void> saveStudentLogin({
    required String identifier,
    required String password,
    required Map<String, dynamic> user,
  }) async {
    final role = user['role']
        ?.toString()
        .trim()
        .toUpperCase();

    if (role != 'STUDENT') {
      return;
    }

    await _storage.write(
      key: _identifierKey,
      value: identifier.trim(),
    );

    await _storage.write(
      key: _passwordKey,
      value: password,
    );

    await _storage.write(
      key: _userKey,
      value: jsonEncode(user),
    );
  }

  static Future<Map<String, dynamic>?>
      authenticateOffline({
    required String identifier,
    required String password,
  }) async {
    final savedIdentifier =
        await _storage.read(
      key: _identifierKey,
    );

    final savedPassword =
        await _storage.read(
      key: _passwordKey,
    );

    final savedUser =
        await _storage.read(
      key: _userKey,
    );

    if (savedIdentifier == null ||
        savedPassword == null ||
        savedUser == null) {
      return null;
    }

    if (identifier.trim() !=
        savedIdentifier.trim()) {
      return null;
    }

    if (password != savedPassword) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(savedUser);

      if (decoded is! Map) {
        return null;
      }

      final user =
          Map<String, dynamic>.from(
        decoded,
      );

      final role = user['role']
          ?.toString()
          .trim()
          .toUpperCase();

      if (role != 'STUDENT') {
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<bool>
      hasOfflineStudentLogin() async {
    final user =
        await _storage.read(
      key: _userKey,
    );

    final identifier =
        await _storage.read(
      key: _identifierKey,
    );

    final password =
        await _storage.read(
      key: _passwordKey,
    );

    return user != null &&
        identifier != null &&
        password != null;
  }

  static Future<void>
      clearOfflineStudentLogin() async {
    await _storage.delete(
      key: _userKey,
    );

    await _storage.delete(
      key: _identifierKey,
    );

    await _storage.delete(
      key: _passwordKey,
    );
  }
}