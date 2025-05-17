import 'package:flutter/material.dart';
import 'package:hackathon/feature/functions/exercise_perform.dart'; // Import ExercisePerform
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class Exercise extends StatefulWidget {
  const Exercise({super.key});

  @override
  State<Exercise> createState() => _ExerciseState();
}

class _ExerciseState extends State<Exercise> {
  int? _pregnancyWeek;
  double? _weight;
  String? _name;
  String? _selectedExerciseKey; // Renamed for clarity (e.g., '1', '2')
  int _setsToPerform = 1; // Default sets

  final Map<String, String> _exerciseMap = {
    '1': "Bicep Curl",
    '2': "Squat",
    '3': "Lateral Raise",
    '4': "Overhead Press",
    '5': "Torso Twist",
  };

  // Map display names to the internal keys used by ExercisePerform.dart
  final Map<String, String> _exerciseDisplayNameToInternalKey = {
    "Bicep Curl": "bicep_curl",
    "Squat": "squat",
    "Lateral Raise": "lateral_raise",
    "Overhead Press": "overhead_press",
    "Torso Twist": "torso_twist",
  };

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
      if (_exerciseMap.isNotEmpty) {
        _selectedExerciseKey = _exerciseMap.keys.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            _buildExerciseSelectionCard(),
            const SizedBox(height: 24),
            _buildStartWorkoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_pregnancyWeek == null || _weight == null || _name == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_name!}!',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildStatItem(
                  'Pregnancy Week',
                  '$_pregnancyWeek',
                  Icons.calendar_today_outlined,
                  Colors.pink.shade400,
                ),
                _buildStatItem(
                  'Current Weight',
                  '${_weight!.toStringAsFixed(1)} kg',
                  Icons.monitor_weight_outlined,
                  Colors.purple.shade300,
                ),
              ],
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
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildExerciseSelectionCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Choose Your Exercise',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Exercise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(
                  Icons.fitness_center,
                  color: Colors.pink.shade400,
                ),
              ),
              value: _selectedExerciseKey,
              items:
                  _exerciseMap.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key, // Use the key ('1', '2') as value
                      child: Text(
                        entry.value, // Display the name ("Bicep Curl")
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedExerciseKey = newValue;
                });
              },
              validator:
                  (value) => value == null ? 'Please select an exercise' : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Sets to Perform: $_setsToPerform',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Slider(
              value: _setsToPerform.toDouble(),
              min: 1,
              max: 10, // Max 10 sets
              divisions: 9,
              label: _setsToPerform.toString(),
              activeColor: Colors.pink.shade400,
              inactiveColor: Colors.pink.shade100,
              onChanged: (double value) {
                setState(() {
                  _setsToPerform = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartWorkoutButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow, size: 28),
        label: Text(
          'Start Workout',
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          // Make onPressed async to await Navigator.push
          if (_selectedExerciseKey != null) {
            final String? exerciseDisplayName =
                _exerciseMap[_selectedExerciseKey!];
            final String? exerciseInternalKey =
                exerciseDisplayName != null
                    ? _exerciseDisplayNameToInternalKey[exerciseDisplayName]
                    : null;

            if (exerciseInternalKey != null) {
              // Navigate to ExercisePerform screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ExercisePerform(
                        targetReps: _setsToPerform, // Pass sets as targetReps
                        initialExerciseType: exerciseInternalKey,
                      ),
                ),
              );

              // Handle the result from ExercisePerform if needed
              if (result != null && result is Map && mounted) {
                int achievedReps = result['reps'] ?? 0;
                bool completed = result['completed'] ?? false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Workout ${completed ? "completed" : "ended"}. Reps: $achievedReps/$_setsToPerform',
                    ),
                    backgroundColor:
                        completed
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Selected exercise is not configured for performance tracking.',
                  ),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select an exercise first.'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 5.0,
        ),
      ),
    );
  }
}
