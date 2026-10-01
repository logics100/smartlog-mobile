import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class AdminAppearanceScreen extends StatefulWidget {
  const AdminAppearanceScreen({super.key});
  @override
  State<AdminAppearanceScreen> createState() => _AdminAppearanceScreenState();
}

class _AdminAppearanceScreenState extends State<AdminAppearanceScreen> {
  static const navy = Color(0xFF062B63);
  static const blue = Color(0xFF087BEA);
  List<Map<String, dynamic>> slots = [];
  bool loading = true;
  String? busy;
  String? error;
  Map<String, String> get headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${ApiService.token}',
  };

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/admin/appearance'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) {
        throw Exception('Server ${r.statusCode}: ${r.body}');
      }
      final decoded = jsonDecode(r.body) as Map<String, dynamic>;
      if (mounted) {
        setState(
          () => slots = (decoded['slots'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> replace(Map<String, dynamic> slot) async {
    final key = slot['key'].toString();
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        message('Select an image smaller than 8 MB.');
        return;
      }
      setState(() => busy = key);
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/admin/appearance/$key'),
      );
      req.headers.addAll(headers);
      req.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: photo.name),
      );
      final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 45)),
      );
      if (res.statusCode != 200) {
        throw Exception('Upload failed (${res.statusCode}): ${res.body}');
      }
      message('Image updated.');
      await refresh();
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  Future<void> reset(Map<String, dynamic> slot) async {
    final key = slot['key'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore default?'),
        content: Text('Restore the default image for ${slot['title']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = key);
    try {
      final r = await http
          .delete(
            Uri.parse('${ApiService.baseUrl}/admin/appearance/$key'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        throw Exception('Reset failed (${r.statusCode}): ${r.body}');
      }
      message('Default restored.');
      await refresh();
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F9FD),
    appBar: AppBar(
      title: const Text('Appearance & Images'),
      backgroundColor: navy,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: loading ? null : refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: refresh, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Manage SmartLog Images',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Changes are shared with the SmartLog web portal.'),
                const SizedBox(height: 16),
                ...slots.map((slot) {
                  final working = busy == slot['key'];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot['title'].toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(slot['description'].toString()),
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 1.9,
                            child: Container(
                              color: const Color(0xFFEAF2F8),
                              child: Image.network(
                                slot['url'].toString(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text('Preview unavailable'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slot['custom_exists'] == true
                                ? 'Custom image'
                                : 'Default image',
                            style: const TextStyle(
                              color: blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: busy == null
                                    ? () => replace(slot)
                                    : null,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  working ? 'Working...' : 'Replace image',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: blue,
                                ),
                              ),
                              if (slot['custom_exists'] == true)
                                OutlinedButton.icon(
                                  onPressed: busy == null
                                      ? () => reset(slot)
                                      : null,
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore default'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
  );
}
