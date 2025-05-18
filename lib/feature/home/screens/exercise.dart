import 'package:flutter/material.dart';
import 'package:hackathon/feature/functions/exercise_perform.dart'; // Import ExercisePerform
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- New Modern Color Palette ---
const Color kExercisePrimaryColor = Color(0xFF6A1B9A); // Deep Purple
const Color kExerciseAccentColor = Color(0xFFEC407A); // Vibrant Pink
const Color kExerciseBackgroundColor = Color(0xFFF3E5F5); // Light Lavender
const Color kExerciseCardColor = Colors.white;
const Color kExerciseTextColor = Color(0xFF372841); // Dark Purple-Gray
const Color kExerciseSecondaryTextColor = Color(
  0xFF7B6B8C,
); // Muted Purple-Gray
const Color kExerciseSuccessColor = Color(0xFF2E7D32); // Dark Green
const Color kExerciseWarningColor = Color(0xFFEF6C00); // Orange
// --- End New Modern Color Palette ---

class Exercise extends StatefulWidget {
  const Exercise({super.key});

  @override
  State<Exercise> createState() => _ExerciseState();
}

class _ExerciseState extends State<Exercise> {
  int? _pregnancyWeek;
  double? _weight;
  String? _name;
  String?
  _selectedExerciseInternalKey; // Stores the internal key like "bicep_curl"
  int _setsToPerform = 1;

  // Maps internal keys to display names and icons
  final Map<String, Map<String, dynamic>> _exerciseDetails = {
    "bicep_curl": {"name": "Bicep Curl", "icon": Icons.fitness_center},
    "squat": {"name": "Squat", "icon": Icons.accessibility_new},
    "lateral_raise": {"name": "Lateral Raise", "icon": Icons.straighten},
    "overhead_press": {"name": "Overhead Press", "icon": Icons.arrow_upward},
    "torso_twist": {"name": "Torso Twist", "icon": Icons.rotate_right},
  };

  // This map is no longer needed as we directly use internal keys.
  // final Map<String, String> _exerciseDisplayNameToInternalKey = { ... };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pregnancyWeek = prefs.getInt('pregnancyWeek');
      _weight = prefs.getDouble('weight');
      _name = prefs.getString('name');
      if (_exerciseDetails.isNotEmpty) {
        _selectedExerciseInternalKey =
            _exerciseDetails.keys.first; // Default selection
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kExerciseBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Workout',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: kExercisePrimaryColor,
          ),
        ),
        backgroundColor: kExerciseCardColor,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: kExercisePrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildGreetingHeader(),
            const SizedBox(height: 20),
            _buildUserInfoCard(),
            const SizedBox(height: 28),
            _buildSectionTitle('Choose Your Exercise'),
            const SizedBox(height: 16),
            _buildExerciseGrid(),
            const SizedBox(height: 28),
            _buildSectionTitle('Set Your Intensity'),
            const SizedBox(height: 16),
            _buildSetsSelectorCard(),
            const SizedBox(height: 32),
            _buildStartWorkoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    if (_name == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'Hello, ${_name!}!',
        style: GoogleFonts.lato(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: kExercisePrimaryColor,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: kExerciseTextColor,
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_pregnancyWeek == null || _weight == null) {
      return const Center(
        child: CircularProgressIndicator(color: kExercisePrimaryColor),
      );
    }
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: kExerciseCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildStatItem(
              'Pregnancy Week',
              '$_pregnancyWeek',
              Icons.calendar_today_outlined,
              kExerciseAccentColor,
            ),
            Container(height: 50, width: 1, color: Colors.grey.shade300),
            _buildStatItem(
              'Current Weight',
              '${_weight!.toStringAsFixed(1)} kg',
              Icons.monitor_weight_outlined,
              kExercisePrimaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: iconColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kExerciseTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: kExerciseSecondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseGrid() {
    if (_exerciseDetails.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Or 3 for smaller tiles
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2, // Adjust for desired tile shape
      ),
      itemCount: _exerciseDetails.length,
      itemBuilder: (context, index) {
        final internalKey = _exerciseDetails.keys.elementAt(index);
        final details = _exerciseDetails[internalKey]!;
        final bool isSelected = _selectedExerciseInternalKey == internalKey;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedExerciseInternalKey = internalKey;
            });
          },
          child: Card(
            elevation: isSelected ? 4.0 : 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: isSelected ? kExerciseAccentColor : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            color: isSelected ? kExerciseAccentColor : kExerciseCardColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  details["icon"] as IconData,
                  size: 40,
                  color:
                      isSelected ? kExerciseCardColor : kExercisePrimaryColor,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    details["name"] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color:
                          isSelected ? kExerciseCardColor : kExerciseTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetsSelectorCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: kExerciseCardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of Sets: $_setsToPerform',
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: kExerciseTextColor,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kExercisePrimaryColor,
                inactiveTrackColor: kExercisePrimaryColor.withOpacity(0.3),
                trackShape: const RoundedRectSliderTrackShape(),
                trackHeight: 6.0,
                thumbColor: kExerciseAccentColor,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12.0,
                ),
                overlayColor: kExerciseAccentColor.withAlpha(
                  (0.32 * 255).round(),
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 24.0,
                ),
                tickMarkShape: const RoundSliderTickMarkShape(),
                activeTickMarkColor: kExerciseAccentColor,
                inactiveTickMarkColor: kExercisePrimaryColor.withOpacity(0.5),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                valueIndicatorColor: kExerciseAccentColor,
                valueIndicatorTextStyle: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: _setsToPerform.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _setsToPerform.toString(),
                onChanged: (double value) {
                  setState(() {
                    _setsToPerform = value.round();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartWorkoutButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          'Start Workout',
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          if (_selectedExerciseInternalKey != null) {
            final String exerciseInternalKey = _selectedExerciseInternalKey!;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ExercisePerform(
                      targetReps: _setsToPerform,
                      initialExerciseType: exerciseInternalKey,
                    ),
              ),
            );

            if (result != null && result is Map && mounted) {
              int achievedReps = result['reps'] ?? 0;
              bool completed = result['completed'] ?? false;
              _showWorkoutCompletionSnackbar(completed, achievedReps);

              if (completed) {
                _fetchAndShowFeedback(exerciseInternalKey, achievedReps);
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please select an exercise first.',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                backgroundColor: kExerciseWarningColor,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kExercisePrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 4.0,
          shadowColor: kExercisePrimaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showWorkoutCompletionSnackbar(bool completed, int achievedReps) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workout ${completed ? "completed" : "ended"}. Sets: $achievedReps/$_setsToPerform',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor:
            completed ? kExerciseSuccessColor : kExerciseWarningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _fetchAndShowFeedback(
    String exerciseName, // This is already the internal key
    int completedSets,
  ) async {
    // Show loading bottom sheet first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: kExerciseCardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Generating Your Feedback...',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kExercisePrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hang tight! We\'re analyzing your performance to provide personalized tips.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    color: kExerciseSecondaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: kExerciseAccentColor),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );

    try {
      final hour = DateTime.now().hour;
      String timeOfDay = "afternoon";
      if (hour < 12) {
        timeOfDay = "morning";
      } else if (hour >= 18) {
        timeOfDay = "evening";
      }

      final requestBody = {
        "week_pregnancy": _pregnancyWeek,
        "n_sets": completedSets,
        "time": timeOfDay,
        "name": exerciseName, // Use the direct internal key
      };

      final response = await http.post(
        Uri.parse('http://192.168.105.156:8000/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (mounted) Navigator.pop(context); // Close loading sheet

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final feedback = responseData['feedback'] as String;
        final finalAnswerStart = feedback.indexOf('FINAL ANSWER:');
        String cleanFeedback = feedback;
        if (finalAnswerStart != -1) {
          cleanFeedback =
              feedback
                  .substring(finalAnswerStart + 'FINAL ANSWER:'.length)
                  .replaceAll('```', '')
                  .trim();
        }

        if (mounted) {
          _showFeedbackModal(cleanFeedback);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to get feedback. Status: ${response.statusCode}',
                style: GoogleFonts.lato(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading sheet if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching feedback: ${e.toString()}',
              style: GoogleFonts.lato(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _showFeedbackModal(String feedbackContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: kExerciseCardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              32,
            ), // More bottom padding for button
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  // Handle for draggability
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Workout Insights ✨',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kExercisePrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  // Use Expanded for scrollable content
                  child: SingleChildScrollView(
                    child: Text(
                      feedbackContent,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: kExerciseTextColor,
                        height: 1.5, // Improved line spacing
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kExerciseAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      textStyle: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Got it!'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
