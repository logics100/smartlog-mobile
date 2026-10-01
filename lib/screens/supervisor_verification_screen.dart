import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'supervisor_reference_face_screen.dart';
import '../services/api_service.dart';
import '../widgets/signature_pad.dart';

class SupervisorVerificationScreen extends StatefulWidget {
  final int? entryId;
  final int? attendanceId;

  final String procedureName;
  final String? facilityName;

  const SupervisorVerificationScreen({
    super.key,
    this.entryId,
    this.attendanceId,
    required this.procedureName,
    this.facilityName,
  }) : assert(
         entryId != null || attendanceId != null,
         'Either entryId or attendanceId must be provided.',
       );

  @override
  State<SupervisorVerificationScreen> createState() =>
      _SupervisorVerificationScreenState();
}

class _SupervisorVerificationScreenState
    extends State<SupervisorVerificationScreen> {
  final searchController = TextEditingController();
  final supervisorController = TextEditingController();
  final facilityController = TextEditingController();

  final GlobalKey signatureBoundaryKey = GlobalKey();

  final GlobalKey<SignaturePadState> signaturePadKey =
      GlobalKey<SignaturePadState>();

  final ImagePicker imagePicker = ImagePicker();

  Uint8List? faceBytes;

  List<dynamic> supervisorResults = [];

  Map<String, dynamic>? selectedSupervisor;

  bool searching = false;
  bool submitting = false;
  bool capturingFace = false;
  bool useGuestSupervisor = false;

  Timer? searchDebounce;

  @override
  void initState() {
    super.initState();

    if (widget.facilityName != null) {
      facilityController.text = widget.facilityName!;
    }
  }

  // ---------------------------------------------------------------------------
  // Search Registered Supervisors
  // ---------------------------------------------------------------------------

  void onSearchChanged(String value) {
    searchDebounce?.cancel();

    final search = value.trim();

    if (search.isEmpty) {
      setState(() {
        supervisorResults = [];
      });

      return;
    }

    searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchSupervisors(search);
    });
  }

  Future<void> searchSupervisors(String search) async {
    if (search.trim().isEmpty) {
      return;
    }

    setState(() {
      searching = true;
    });

    try {
      final results = await ApiService.searchClinicalSupervisors(search.trim());

      if (!mounted) return;

      setState(() {
        supervisorResults = results;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to search supervisors: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          searching = false;
        });
      }
    }
  }

  void selectSupervisor(Map<String, dynamic> supervisor) {
    setState(() {
      selectedSupervisor = supervisor;

      supervisorController.text = supervisor['full_name']?.toString() ?? '';

      facilityController.text = supervisor['facility_name']?.toString() ?? '';

      supervisorResults = [];

      searchController.text = supervisor['full_name']?.toString() ?? '';
    });

    FocusScope.of(context).unfocus();
  }

  void changeSupervisor() {
    setState(() {
      selectedSupervisor = null;

      supervisorController.clear();

      searchController.clear();

      supervisorResults = [];

      facilityController.text = widget.facilityName ?? '';
    });
  }

  // ---------------------------------------------------------------------------
  // Signature
  // ---------------------------------------------------------------------------

  Future<Uint8List?> captureSignature() async {
    try {
      final boundary =
          signatureBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void clearSignature() {
    signaturePadKey.currentState?.clear();
  }

  // ---------------------------------------------------------------------------
  // Face Capture
  // ---------------------------------------------------------------------------

  Future<void> captureFace() async {
    setState(() {
      capturingFace = true;
    });

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1280,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        faceBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to capture face image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          capturingFace = false;
        });
      }
    }
  }

  void removeFaceCapture() {
    setState(() {
      faceBytes = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Submit Verification
  // ---------------------------------------------------------------------------

  Future<void> submitVerification() async {
    int? supervisorId;

    if (!useGuestSupervisor) {
      if (selectedSupervisor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a registered supervisor.'),
          ),
        );
        return;
      }

      supervisorId = int.tryParse(selectedSupervisor!['id'].toString());

      if (supervisorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid supervisor selected.')),
        );
        return;
      }
    }

    final supervisorName = supervisorController.text.trim();

    if (supervisorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supervisor name is missing.')),
      );

      return;
    }

    final signatureState = signaturePadKey.currentState;

    if (signatureState == null || !signatureState.hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supervisor signature is required.')),
      );

      return;
    }

    if (faceBytes == null || faceBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture the supervisor face image.'),
        ),
      );

      return;
    }

    final signatureBytes = await captureSignature();

    if (signatureBytes == null || signatureBytes.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to capture the signature. '
            'Please try again.',
          ),
        ),
      );

      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      late final Map<String, dynamic> result;

      if (widget.attendanceId != null) {
        result = await ApiService.verifyStudentAttendance(
          attendanceId: widget.attendanceId!,
          clinicalSupervisorId: supervisorId,
          supervisorName: supervisorName,
          facilityName: facilityController.text.trim().isEmpty
              ? null
              : facilityController.text.trim(),
          signatureBytes: signatureBytes,
          faceBytes: faceBytes,
        );
      } else {
        result = await ApiService.verifyClinicalEntry(
          entryId: widget.entryId!,
          clinicalSupervisorId: supervisorId,
          supervisorName: supervisorName,
          facilityName: facilityController.text.trim().isEmpty
              ? null
              : facilityController.text.trim(),
          signatureBytes: signatureBytes,
          faceBytes: faceBytes,
        );
      }

      if (!mounted) return;

      final verificationStatus =
          result['verification_status']?.toString() ?? 'MANUAL_REVIEW';

      final faceComparison = result['face_comparison'];

      String comparisonDecision = 'NOT_AVAILABLE';

      String distanceText = 'N/A';

      if (faceComparison is Map) {
        comparisonDecision =
            faceComparison['comparison_decision']?.toString() ??
            'NOT_AVAILABLE';

        final distance = faceComparison['lbph_distance'];

        if (distance != null) {
          final parsedDistance = double.tryParse(distance.toString());

          if (parsedDistance != null) {
            distanceText = parsedDistance.toStringAsFixed(4);
          }
        }
      }

      String comparisonMessage;

      switch (comparisonDecision) {
        case 'LIKELY_MATCH':
          comparisonMessage =
              'The captured face is similar to '
              'the registered supervisor '
              'reference face.';
          break;

        case 'LIKELY_DIFFERENT':
          comparisonMessage =
              'The captured face appears '
              'different from the registered '
              'supervisor reference face.';
          break;

        case 'INCONCLUSIVE':
          comparisonMessage =
              'The face comparison was '
              'inconclusive. Manual review '
              'is required.';
          break;

        default:
          comparisonMessage =
              'Face comparison was not '
              'available. Manual review '
              'is required.';
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.fact_check_outlined),
                SizedBox(width: 10),
                Expanded(child: Text('Verification Submitted')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Face Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    comparisonDecision,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(comparisonMessage),

                  const SizedBox(height: 16),

                  Text(
                    'LBPH Distance: '
                    '$distanceText',
                  ),

                  const SizedBox(height: 20),

                  const Divider(),

                  const SizedBox(height: 12),

                  const Text(
                    'Verification Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    verificationStatus,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'The face comparison is '
                    'supporting evidence only. '
                    'The verification remains '
                    'under manual review.',
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    searchDebounce?.cancel();

    searchController.dispose();
    supervisorController.dispose();
    facilityController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------------
            // Clinical Activity
            // ---------------------------------------------------------------

            const Text(
              'Clinical Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              widget.procedureName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Supervisor Type
            // ---------------------------------------------------------------
            const Text(
              'Supervisor Type',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.verified_user_outlined),
                  label: Text('Registered'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.person_add_alt_1_outlined),
                  label: Text('Other Supervisor'),
                ),
              ],
              selected: {useGuestSupervisor},
              onSelectionChanged: (selection) {
                final guest = selection.first;
                setState(() {
                  useGuestSupervisor = guest;
                  selectedSupervisor = null;
                  supervisorResults = [];
                  searchController.clear();
                  supervisorController.clear();
                  facilityController.text = widget.facilityName ?? '';
                  faceBytes = null;
                });
              },
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------------------
            // Registered Supervisor / Guest Supervisor
            // ---------------------------------------------------------------
            if (!useGuestSupervisor) ...[
              const Text(
                'Registered Supervisor',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Search and select the supervisor '
                'who is verifying this activity.',
              ),

              const SizedBox(height: 12),

              if (selectedSupervisor == null) ...[
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search Supervisor',
                    hintText: 'Name or registration number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),

                if (supervisorResults.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: supervisorResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final supervisor = Map<String, dynamic>.from(
                          supervisorResults[index],
                        );

                        final name =
                            supervisor['full_name']?.toString() ??
                            'Unknown Supervisor';

                        final registration =
                            supervisor['registration_number']?.toString() ??
                            'No registration number';

                        final profession =
                            supervisor['profession']?.toString() ?? '';

                        final facility =
                            supervisor['facility_name']?.toString() ?? '';

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            [
                              if (profession.isNotEmpty) profession,
                              registration,
                              if (facility.isNotEmpty) facility,
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            selectSupervisor(supervisor);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              selectedSupervisor!['full_name']?.toString() ??
                                  '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Registration: '
                        '${selectedSupervisor!['registration_number'] ?? 'N/A'}',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Profession: '
                        '${selectedSupervisor!['profession'] ?? 'N/A'}',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Facility: '
                        '${selectedSupervisor!['facility_name'] ?? 'N/A'}',
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: changeSupervisor,
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Change Supervisor'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final supervisorId = int.parse(
                                  selectedSupervisor!['id'].toString(),
                                );

                                final supervisorName =
                                    selectedSupervisor!['full_name']
                                        ?.toString() ??
                                    '';

                                final registrationNumber =
                                    selectedSupervisor!['registration_number']
                                        ?.toString() ??
                                    '';

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SupervisorReferenceFaceScreen(
                                          supervisorId: supervisorId,
                                          supervisorName: supervisorName,
                                          registrationNumber:
                                              registrationNumber,
                                        ),
                                  ),
                                );

                                if (!context.mounted) {
                                  return;
                                }

                                if (result == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Reference face registered successfully.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.face_retouching_natural),
                              label: const Text('Reference Face'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Use this option when the supervisor is not registered in SmartLog. '
                  'Enter the supervisor name and facility below. Their signature and '
                  'face photo will be stored for lecturer review.',
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---------------------------------------------------------------
            // Supervisor Name
            // ---------------------------------------------------------------
            TextField(
              controller: supervisorController,
              readOnly: !useGuestSupervisor,
              decoration: InputDecoration(
                labelText: useGuestSupervisor
                    ? 'Other Supervisor Full Name'
                    : 'Supervisor Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // Facility
            // ---------------------------------------------------------------
            TextField(
              controller: facilityController,
              readOnly: !useGuestSupervisor && selectedSupervisor != null,
              decoration: const InputDecoration(
                labelText: 'Facility',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Signature
            // ---------------------------------------------------------------
            const Text(
              'Supervisor Signature',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SignaturePad(
              key: signaturePadKey,
              signatureKey: signatureBoundaryKey,
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: clearSignature,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Signature'),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Face Capture
            // ---------------------------------------------------------------
            const Text(
              'Supervisor Face Capture',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (faceBytes == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.face_outlined, size: 50),

                    const SizedBox(height: 12),

                    const Text(
                      'Capture the supervisor '
                      'face using the front '
                      'camera.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: capturingFace ? null : captureFace,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: capturingFace
                          ? const Text('Opening Camera...')
                          : const Text('Capture Face'),
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
                      faceBytes!,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: capturingFace ? null : captureFace,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Retake'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: removeFaceCapture,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Information
            // ---------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      useGuestSupervisor
                          ? 'This supervisor is not registered in SmartLog. Their name, '
                                'facility, signature and face photo will be stored as evidence. '
                                'No reference-face comparison is available, so the verification '
                                'remains under manual lecturer review.'
                          : 'The selected registered supervisor, signature and face photo '
                                'will be stored with this verification. The captured face may be '
                                'compared with the registered reference face. The result is '
                                'supporting evidence only and remains under manual review.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ---------------------------------------------------------------
            // Submit
            // ---------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: submitting ? null : submitVerification,
                icon: const Icon(Icons.verified_user_outlined),
                label: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
