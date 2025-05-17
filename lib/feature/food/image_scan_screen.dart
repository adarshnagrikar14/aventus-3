import 'dart:io';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageScanScreen extends StatefulWidget {
  const ImageScanScreen({super.key});

  @override
  State<ImageScanScreen> createState() => _ImageScanScreenState();
}

class _ImageScanScreenState extends State<ImageScanScreen> {
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _foodData;

  // Define a modern color palette
  final Color _primaryColor = Colors.teal.shade600;
  final Color _accentColor = Colors.orange.shade700;
  final Color _backgroundColor = Colors.grey.shade100;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _secondaryTextColor = Colors.grey.shade700;
  final Color _tertiaryTextColor = Colors.grey.shade500;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;

    if (cameraStatus.isDenied || photosStatus.isDenied) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.photos].request();
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
                    color: _primaryColor,
                  ),
                ),
                content: Text(
                  'Please enable ${source == ImageSource.camera ? 'camera' : 'photos'} access in app settings to use this feature.',
                  style: GoogleFonts.lato(color: _secondaryTextColor),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lato(color: _secondaryTextColor),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Scan Your Meal',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            if (_isLoading)
              _buildLoadingState()
            else if (_foodData != null)
              _buildResultsSection()
            else
              _buildInitialState(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          height: 220,
          child:
              _image != null
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_image!, fit: BoxFit.cover),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text('Retake', style: GoogleFonts.lato()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor.withOpacity(0.9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_outlined,
                        size: 60,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to scan your food',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: _secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use camera or gallery',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: _tertiaryTextColor,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 20),
            Text(
              'Analyzing your meal...',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: _secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'This might take a moment.',
              style: GoogleFonts.lato(fontSize: 14, color: _tertiaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_search_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to see what\'s in your food?',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: _secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan an image to get started.',
              style: GoogleFonts.lato(fontSize: 15, color: _tertiaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final foodName = _foodData?['name'] as String? ?? 'Unknown Food';
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Text(
            foodName,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          if (_foodData?['description'] != null &&
              (_foodData!['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _foodData!['description'],
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: _secondaryTextColor,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildNutritionCard(),
          const SizedBox(height: 16),
          if ((_foodData?['ingredients'] as List?)?.isNotEmpty ?? false)
            _buildIngredientsCard(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Implement Add to Meal Log functionality
              // This would typically involve passing _foodData to MealLogScreen or a Cubit
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$foodName added to meal log (simulation).',
                    style: GoogleFonts.lato(),
                  ),
                  backgroundColor: _accentColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_task_rounded),
            label: Text(
              'Add to Meal Log',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Nutrition',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientProgressBar(
              'Calories',
              double.tryParse(_foodData?['calories']?.toString() ?? '0') ?? 0.0,
              2000, // Daily recommended value (example)
              Colors.amber.shade700,
              'kcal',
            ),
            _buildNutrientProgressBar(
              'Protein',
              double.tryParse(_foodData?['protein']?.toString() ?? '0') ?? 0.0,
              50, // Daily recommended value (example)
              Colors.lightGreen.shade600,
              'g',
            ),
            _buildNutrientProgressBar(
              'Carbs',
              double.tryParse(_foodData?['carbs']?.toString() ?? '0') ?? 0.0,
              300, // Daily recommended value (example)
              Colors.lightBlue.shade600,
              'g',
            ),
            _buildNutrientProgressBar(
              'Fat',
              double.tryParse(_foodData?['fat']?.toString() ?? '0') ?? 0.0,
              70, // Daily recommended value (example)
              Colors.pink.shade400,
              'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientProgressBar(
    String label,
    double value,
    double maxValue,
    Color color,
    String unit,
  ) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          if (maxValue > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(0)}% of daily goal (approx.)',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: _tertiaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    final ingredients =
        (_foodData?['ingredients'] as List?)?.cast<String>() ?? [];
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Possible Ingredients',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  ingredients.map((ingredient) {
                    return Chip(
                      label: Text(
                        ingredient,
                        style: GoogleFonts.lato(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose Image Source',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt_rounded,
                      color: _primaryColor,
                    ),
                    title: Text(
                      'Take a Photo',
                      style: GoogleFonts.lato(fontSize: 16, color: _textColor),
                    ),
                    onTap: () async {
                      if (await _handlePermissions(ImageSource.camera)) {
                        // ignore: use_build_context_synchronously
                        final XFile? pickedImage = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context, pickedImage);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library_rounded,
                      color: _primaryColor,
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: GoogleFonts.lato(fontSize: 16, color: _textColor),
                    ),
                    onTap: () async {
                      if (await _handlePermissions(ImageSource.gallery)) {
                        // ignore: use_build_context_synchronously
                        final XFile? pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context, pickedImage);
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
        _image = File(image.path);
        _foodData = null; // Reset previous data
      });
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      const apiKey =
          'AIzaSyB4kcWMemFLQ8dkJqgdTsOmN1NN5pwO30o'; // Keep your API key secure
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''Analyze this food image and provide nutritional estimates in this JSON format:
                {
                  "name": "Food name (e.g., Chicken Salad, Spaghetti Bolognese)",
                  "description": "A brief, appealing description of the meal, 2-3 sentences.",
                  "calories": "Estimate total calories (number only, e.g., 450)",
                  "protein": "Estimate protein in grams (number only, e.g., 30)",
                  "carbs": "Estimate carbs in grams (number only, e.g., 50)",
                  "fat": "Estimate fat in grams (number only, e.g., 15)",
                  "ingredients": ["List key visible ingredients as strings, e.g., "Chicken Breast", "Lettuce", "Tomato"]
                }
                Provide realistic nutritional estimates based on visible portions. Be concise.
                If the image is not food, respond with:
                {
                  "name": "Not Food",
                  "description": "The image does not appear to be food. Please scan a food item.",
                  "calories": "0", "protein": "0", "carbs": "0", "fat": "0", "ingredients": []
                }''',
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
        }),
      );

      dev.log('Response status: ${response.statusCode}');
      dev.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final candidate = responseData['candidates']?[0];
        final text = candidate?['content']?['parts']?[0]?['text'] as String?;

        if (text == null) {
          throw Exception('No text found in API response.');
        }

        String jsonStr =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final startIndex = jsonStr.indexOf('{');
        final endIndex = jsonStr.lastIndexOf('}') + 1;

        if (startIndex == -1 || endIndex <= startIndex) {
          throw Exception('Valid JSON object not found in response: $jsonStr');
        }
        jsonStr = jsonStr.substring(startIndex, endIndex);
        dev.log('Extracted JSON: $jsonStr');

        try {
          final parsedData = jsonDecode(jsonStr) as Map<String, dynamic>;
          setState(() {
            _foodData = {
              'name': parsedData['name'] ?? 'Unknown Food',
              'description':
                  parsedData['description'] ?? 'No description available.',
              'calories': parsedData['calories']?.toString() ?? '0',
              'protein': parsedData['protein']?.toString() ?? '0',
              'carbs': parsedData['carbs']?.toString() ?? '0',
              'fat': parsedData['fat']?.toString() ?? '0',
              'ingredients':
                  (parsedData['ingredients'] as List?)?.cast<String>() ?? [],
            };
          });
        } catch (e) {
          dev.log('JSON Parse Error', error: e, stackTrace: StackTrace.current);
          throw Exception('Failed to parse food data from API response.');
        }
      } else {
        dev.log('API Error Response: ${response.body}');
        throw Exception(
          'API request failed with status: ${response.statusCode}. Check logs for details.',
        );
      }
    } catch (e, s) {
      dev.log('Error analyzing image', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.lato(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _analyzeImage,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
