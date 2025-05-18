import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'dart:async';

// Define a professional color palette
const Color kPrescriptionPrimaryColor = Color(0xFF00796B); // Teal
const Color kPrescriptionAccentColor = Color(0xFFF9A825); // Amber
const Color kPrescriptionBackgroundColor = Color(0xFFE0F2F1); // Light Teal
const Color kPrescriptionCardColor = Colors.white;
const Color kPrescriptionTextColor = Color(0xFF263238); // Blue Grey Dark
const Color kPrescriptionSecondaryTextColor = Color(0xFF546E7A); // Blue Grey
const Color kPrescriptionErrorColor = Color(0xFFD32F2F); // Red

void showPrescriptionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important for taller content
    backgroundColor: Colors.transparent, // Allows custom shape
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.75, // Start at 75% height
          minChildSize: 0.4,
          maxChildSize: 0.95, // Allow almost full screen
          expand: false,
          builder: (_, controller) => PresSheet(scrollController: controller),
        ),
  );
}

class PresSheet extends StatefulWidget {
  final ScrollController? scrollController;
  const PresSheet({super.key, this.scrollController});

  @override
  State<PresSheet> createState() => _PresSheetState();
}

class _PresSheetState extends State<PresSheet> {
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _prescriptionData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;

    if (cameraStatus.isDenied || photosStatus.isDenied) {
      // Optionally, show a less intrusive notice or rely on _handlePermissions later
      dev.log("Permissions initially denied. Will request on action.");
    }
  }

  Future<bool> _handlePermissions(ImageSource source) async {
    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    PermissionStatus status = await permission.status;

    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Permission Required',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: kPrescriptionPrimaryColor,
                  ),
                ),
                content: Text(
                  'Please enable ${source == ImageSource.camera ? 'camera' : 'photos'} access in app settings to use this feature.',
                  style: GoogleFonts.lato(
                    color: kPrescriptionSecondaryTextColor,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lato(
                        color: kPrescriptionSecondaryTextColor,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrescriptionPrimaryColor,
                    ),
                    child: Text('Open Settings', style: GoogleFonts.lato()),
                  ),
                ],
              ),
        );
      }
      return false;
    }

    if (status.isDenied) {
      status = await permission.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: kPrescriptionCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Prescription Image',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrescriptionPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_rounded,
                      color: kPrescriptionPrimaryColor,
                    ),
                    title: Text(
                      'Take a Photo',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: kPrescriptionTextColor,
                      ),
                    ),
                    onTap: () async {
                      if (await _handlePermissions(ImageSource.camera)) {
                        final XFile? pickedImage = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (mounted) Navigator.pop(context, pickedImage);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: kPrescriptionPrimaryColor,
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: kPrescriptionTextColor,
                      ),
                    ),
                    onTap: () async {
                      if (await _handlePermissions(ImageSource.gallery)) {
                        final XFile? pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (mounted) Navigator.pop(context, pickedImage);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _prescriptionData = null;
        _errorMessage = null;
      });
      await _analyzePrescriptionImage();
    }
  }

  Future<void> _analyzePrescriptionImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _prescriptionData = null;
    });

    try {
      const String url =
          'http://192.168.105.156:8000/parse_prescription_gemini';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      dev.log('Sending request to $url');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      dev.log('Response status: ${response.statusCode}');
      dev.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _prescriptionData = data;
        });
      } else {
        dev.log('API Error Response: ${response.body}');
        String errorMsg =
            'Failed to parse prescription. Status: ${response.statusCode}.';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('detail')) {
            errorMsg += ' ${errorData['detail']}';
          }
        } catch (_) {
          errorMsg += ' Could not parse error detail.';
        }
        throw Exception(errorMsg);
      }
    } catch (e, s) {
      dev.log('Error analyzing prescription:', error: e, stackTrace: s);
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: kPrescriptionPrimaryColor),
      label: Text(
        label,
        style: GoogleFonts.lato(
          color: kPrescriptionPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: kPrescriptionPrimaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: kPrescriptionPrimaryColor.withOpacity(0.3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Draggable handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Scan Prescription',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrescriptionPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageDisplayAndPicker(),
                const SizedBox(height: 20),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_errorMessage != null)
                  _buildErrorMessage(_errorMessage!)
                else if (_prescriptionData != null)
                  _buildPrescriptionDetails(_prescriptionData!)
                else
                  _buildInitialPrompt(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplayAndPicker() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(
              color: kPrescriptionPrimaryColor.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _imageFile != null
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_imageFile!, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: FloatingActionButton.small(
                          onPressed: _pickImage,
                          backgroundColor: kPrescriptionAccentColor,
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                          ),
                          heroTag: 'pickImageFab',
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_liquid_rounded,
                        size: 60,
                        color: kPrescriptionPrimaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to Scan Prescription',
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: kPrescriptionPrimaryColor,
                        ),
                      ),
                      Text(
                        'Use camera or gallery',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: kPrescriptionSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(kPrescriptionAccentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing Prescription...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: kPrescriptionSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Card(
      color: kPrescriptionErrorColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: kPrescriptionErrorColor, size: 40),
            const SizedBox(height: 8),
            Text(
              'Error',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrescriptionErrorColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: kPrescriptionErrorColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _analyzePrescriptionImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrescriptionErrorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 60,
            color: kPrescriptionSecondaryTextColor.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan your prescription to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: kPrescriptionSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetails(Map<String, dynamic> data) {
    final patientInfo = data['patient_info'] as Map<String, dynamic>?;
    final doctorInfo = data['doctor_info'] as Map<String, dynamic>?;
    final medications = data['medications'] as List<dynamic>?;
    final additionalInstructions = data['additional_instructions'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (patientInfo != null) _buildPatientInfoCard(patientInfo),
        if (doctorInfo != null) _buildDoctorInfoCard(doctorInfo),
        if (medications != null && medications.isNotEmpty)
          _buildMedicationsList(medications),
        if (additionalInstructions != null && additionalInstructions.isNotEmpty)
          _buildAdditionalInstructionsCard(additionalInstructions),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.close_rounded),
          label: Text(
            'Close',
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the bottom sheet
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                kPrescriptionSecondaryTextColor, // Changed color for a less prominent action
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    Map<String, String?> items,
    IconData titleIcon,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kPrescriptionCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, color: kPrescriptionPrimaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrescriptionPrimaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.entries
                .where(
                  (entry) => entry.value != null && entry.value!.isNotEmpty,
                )
                .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key.replaceAll('_', ' ').capitalize()}: ',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w600,
                            color: kPrescriptionTextColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value!,
                            style: GoogleFonts.lato(
                              color: kPrescriptionSecondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildPatientInfoCard(Map<String, dynamic> patientInfo) {
    return _buildInfoCard('Patient Information', {
      'Name': patientInfo['name'] as String?,
      'Date': patientInfo['date'] as String?,
    }, Icons.person_outline_rounded);
  }

  Widget _buildDoctorInfoCard(Map<String, dynamic> doctorInfo) {
    return _buildInfoCard('Doctor Information', {
      'Name': doctorInfo['name'] as String?,
      'Contact': doctorInfo['contact'] as String?,
    }, Icons.medical_services_outlined);
  }

  Widget _buildMedicationsList(List<dynamic> medications) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kPrescriptionCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medication_rounded,
                  color: kPrescriptionPrimaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Medications',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrescriptionPrimaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...medications.map((med) {
              final medication = med as Map<String, dynamic>;
              return _buildMedicationItem(medication);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    final medicineName = medication['medicine'] as String? ?? 'N/A';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicineName,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrescriptionTextColor,
            ),
          ),
          const SizedBox(height: 4),
          if (medication['dosage'] != null)
            Text(
              'Dosage: ${medication['dosage']}',
              style: GoogleFonts.lato(color: kPrescriptionSecondaryTextColor),
            ),
          if (medication['instructions'] != null)
            Text(
              'Instructions: ${medication['instructions']}',
              style: GoogleFonts.lato(color: kPrescriptionSecondaryTextColor),
            ),
          if (medication['purpose'] != null &&
              (medication['purpose'] as String).isNotEmpty &&
              medication['purpose'] != "Unknown")
            Text(
              'Purpose: ${medication['purpose']}',
              style: GoogleFonts.lato(color: kPrescriptionSecondaryTextColor),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _buildActionChip(
              'Set Reminder',
              Icons.alarm_add_rounded,
              () {
                _showReminderSetDialog(context, medicineName);
              },
            ),
          ),
          if (medication !=
              (_prescriptionData!['medications'] as List<dynamic>).last)
            const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _buildAdditionalInstructionsCard(String instructions) {
    return _buildInfoCard('Additional Instructions', {
      'Instructions': instructions,
    }, Icons.info_outline_rounded);
  }
}

void _showReminderSetDialog(BuildContext context, String medicineName) {
  showDialog(
    context: context,
    barrierDismissible: false, // User cannot dismiss by tapping outside
    builder: (BuildContext dialogContext) {
      // Automatically close the dialog after a few seconds
      Timer(const Duration(seconds: 2), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: kPrescriptionCardColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: kPrescriptionPrimaryColor,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Reminder Set!',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrescriptionPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For $medicineName',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: kPrescriptionSecondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper extension for String capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
