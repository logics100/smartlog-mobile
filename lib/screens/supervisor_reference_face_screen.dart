import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class SupervisorReferenceFaceScreen extends StatefulWidget {
  final int supervisorId;
  final String supervisorName;
  final String registrationNumber;

  const SupervisorReferenceFaceScreen({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
    required this.registrationNumber,
  });

  @override
  State<SupervisorReferenceFaceScreen> createState() =>
      _SupervisorReferenceFaceScreenState();
}

class _SupervisorReferenceFaceScreenState
    extends State<SupervisorReferenceFaceScreen> {
  final ImagePicker imagePicker = ImagePicker();

  Uint8List? referenceFaceBytes;

  bool capturing = false;
  bool uploading = false;

  Future<void> captureReferenceFace() async {
    setState(() {
      capturing = true;
    });

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
        maxWidth: 1280,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        referenceFaceBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to capture reference face: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          capturing = false;
        });
      }
    }
  }

  void removeReferenceFace() {
    setState(() {
      referenceFaceBytes = null;
    });
  }

  Future<void> uploadReferenceFace() async {
    if (referenceFaceBytes == null || referenceFaceBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a reference face first.')),
      );

      return;
    }

    setState(() {
      uploading = true;
    });

    try {
      final result = await ApiService.registerSupervisorReferenceFace(
        supervisorId: widget.supervisorId,
        referenceFaceBytes: referenceFaceBytes!,
      );

      if (!mounted) return;

      final path = result['supervisor']?['reference_face_path']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Reference face registered successfully.'
                : 'Reference face registered successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reference face upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Reference Face')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Supervisor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              widget.supervisorName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text('Registration: ${widget.registrationNumber}'),

            const SizedBox(height: 24),

            const Text(
              'Reference Face',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Capture a clear front-facing photo of the registered supervisor. '
              'This image will be stored as the supervisor reference face.',
            ),

            const SizedBox(height: 16),

            if (referenceFaceBytes == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.face_retouching_natural, size: 60),

                    const SizedBox(height: 12),

                    const Text(
                      'No reference face captured yet.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: capturing ? null : captureReferenceFace,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: capturing
                          ? const Text('Opening Camera...')
                          : const Text('Capture Reference Face'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      referenceFaceBytes!,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: capturing ? null : captureReferenceFace,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Retake'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: removeReferenceFace,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'This step only registers the reference image. '
                      'Automatic face comparison will be added later.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: uploading ? null : uploadReferenceFace,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register Reference Face'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
