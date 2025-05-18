import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackathon/feature/home/screens/glb.dart';
import 'package:hackathon/feature/prescription/pres_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences

// --- Modern Color Palette ---
const Color kHomePrimaryColor = Color(0xFF4A55A2); // Deep blue - more modern
const Color kHomeAccentColor = Color(0xFF7895CB); // Lighter blue accent
const Color kHomeBackgroundColor = Color(0xFFF5F5F5); // Light gray background
const Color kHomeCardColor = Colors.white;
const Color kHomeTextColor = Color(0xFF2D3250); // Dark blue-gray
const Color kHomeSecondaryTextColor = Color(0xFF7D8597); // Medium gray
const Color kHomeHighlightColor = Color(
  0xFF7895CB,
); // Accent blue for highlights
// --- End Modern Color Palette ---

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _userName;
  int _currentPregnancyWeek = 1; // Default, will be updated
  bool _isLoading = true;

  // Mock data - will be refined or replaced with dynamic data based on week
  String _babySize = "Loading...";
  String _babyWeight = "Loading...";
  String _babyDevelopmentInfo = "Loading baby development details...";
  String? _scannedReportOutput; // Output from the report scanner

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('name');
      _currentPregnancyWeek = 30; // Set to week 30 for the provided data
      _updateBabyInfoForWeek(_currentPregnancyWeek);
      _isLoading = false;
    });
  }

  // Placeholder: In a real app, this would fetch data based on the week
  void _updateBabyInfoForWeek(int week) {
    // Week 30 data from the provided JSON
    if (week == 30) {
      _babySize = "Size of a large melon";
      _babyWeight = "1.4 Kg (3.08 lbs)";
      _babyDevelopmentInfo =
          "The fetus begins to develop lanugo, fine, soft hair that covers the body.";
    }
    // Keep existing conditions for other weeks
    else if (week <= 4) {
      _babySize = "About the size of a poppy seed";
      _babyWeight = "Tiny!";
      _babyDevelopmentInfo =
          "The blastocyst implants in the uterine wall. Key structures begin to form.";
    } else if (week <= 8) {
      _babySize = "About the size of a raspberry";
      _babyWeight = "Around 1 gram";
      _babyDevelopmentInfo =
          "Major organs like the heart begin to form and function. Facial features are developing.";
    } else if (week <= 12) {
      _babySize = "About the size of a lime";
      _babyWeight = "Around 1 ounce";
      _babyDevelopmentInfo =
          "Fingers and toes are distinct. The baby can make small movements.";
    } else if (week <= 16) {
      _babySize = "About the size of an avocado";
      _babyWeight = "Around 3.5 ounces";
      _babyDevelopmentInfo =
          "The skeleton is starting to harden. You might feel the first flutters (quickening).";
    } else if (week <= 20) {
      _babySize = "About the size of a banana";
      _babyWeight = "Around 10 ounces";
      _babyDevelopmentInfo =
          "The baby can hear sounds. You can likely find out the sex via ultrasound.";
    } else if (week <= 24) {
      _babySize = "About the size of an ear of corn";
      _babyWeight = "Around 1.3 pounds";
      _babyDevelopmentInfo =
          "Lungs are developing. The baby has regular sleep-wake cycles.";
    } else if (week <= 28) {
      _babySize = "About the size of an eggplant";
      _babyWeight = "Around 2.25 pounds";
      _babyDevelopmentInfo =
          "Eyes can open and close. The baby is practicing breathing movements.";
    } else if (week <= 32) {
      _babySize = "About the size of a large jicama";
      _babyWeight = "Around 3.75 pounds";
      _babyDevelopmentInfo =
          "Most organs are fully developed, except for lungs. Fat layers are forming.";
    } else if (week <= 36) {
      _babySize = "About the size of a honeydew melon";
      _babyWeight = "Around 5.75 pounds";
      _babyDevelopmentInfo =
          "The baby is gaining weight rapidly. Lungs are nearly mature. Baby may descend into the pelvis.";
    } else {
      _babySize = "About the size of a small pumpkin";
      _babyWeight = "Around 7-8 pounds";
      _babyDevelopmentInfo =
          "The baby is considered full-term. Lungs are mature. Getting ready for birth!";
    }
  }

  void _show3DModel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GlbScreen()),
    );
  }

  void _scanReport() {
    showPrescriptionSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: kHomePrimaryColor),
        ),
      );
    }

    final int weeksBefore = 4;
    final int weeksAfter = 5;
    final int startWeek = _currentPregnancyWeek - weeksBefore;
    final int endWeek = _currentPregnancyWeek + weeksAfter;

    return Scaffold(
      backgroundColor: kHomeBackgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 80.0,
            floating: false,
            pinned: true,
            backgroundColor: kHomeCardColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Text(
                _userName != null ? 'Hello, ${_userName!}!' : 'Welcome!',
                style: GoogleFonts.roboto(
                  color: kHomePrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Your Pregnancy Journey: Week $_currentPregnancyWeek',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: kHomeSecondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 24
                _buildPregnancyTimeline(startWeek, endWeek),
                const SizedBox(height: 16), // Reduced from 24
                _buildBabyVisualizationCard(),
                const SizedBox(height: 16), // Reduced from 24
                _buildBabyDevelopmentCard(),
                const SizedBox(height: 16), // Reduced from 24
                _buildMedicalReportCard(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyTimeline(int startWeek, int endWeek) {
    return Container(
      decoration: BoxDecoration(
        color: kHomeCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 24,
                  color: kHomePrimaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pregnancy Timeline',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kHomeTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50, // Reduced from 70
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (endWeek - startWeek) + 1,
                itemBuilder: (context, index) {
                  final week = startWeek + index;
                  if (week < 1 || week > 42)
                    return const SizedBox.shrink(); // Max 42 weeks

                  final isCurrentWeek = week == _currentPregnancyWeek;
                  final double size =
                      isCurrentWeek ? 50.0 : 40.0; // Reduced sizes
                  final Color circleColor =
                      isCurrentWeek ? kHomePrimaryColor : Colors.grey.shade300;
                  final Color textColor =
                      isCurrentWeek ? Colors.white : kHomeSecondaryTextColor;

                  return Container(
                    width: size,
                    height: size,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                      // No more shadow
                    ),
                    child: Center(
                      child: Text(
                        week.toString(),
                        style: GoogleFonts.roboto(
                          color: textColor,
                          fontWeight:
                              isCurrentWeek
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          fontSize: isCurrentWeek ? 18 : 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyVisualizationCard() {
    return Container(
      decoration: BoxDecoration(
        color: kHomeCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/baby.jpg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 60,
                          color: kHomeSecondaryTextColor,
                        ),
                      ),
                    ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kHomeCardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 20,
                        color: kHomePrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Baby Visualizer',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kHomeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.threed_rotation_rounded, size: 20),
              label: Text(
                'View 3D Model',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: _show3DModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: kHomePrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabyDevelopmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: kHomeCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kHomePrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 20,
                    color: kHomePrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Week $_currentPregnancyWeek Development',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kHomeTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kHomePrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.straighten_outlined,
                          color: kHomePrimaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Size',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            color: kHomeTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _babySize,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: kHomeSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kHomePrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          color: kHomePrimaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Weight',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            color: kHomeTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _babyWeight,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: kHomeSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kHomePrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Developments',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kHomeTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _babyDevelopmentInfo,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: kHomeSecondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kHomePrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common Issues',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kHomeTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCommonIssueItem(
                    "Frequent urination scurries back, keeping you on the move.",
                    "You are doing great! Stay hydrated and plan for bathroom breakfast your body's magic.",
                  ),
                  const SizedBox(height: 10),
                  _buildCommonIssueItem(
                    "Braxton-Hicks contractions dance like practice runs for labor.",
                    "You have got this, mama! Rest and hydrate to calm those practice contractions kindly.",
                  ),
                  const SizedBox(height: 10),
                  _buildCommonIssueItem(
                    "Tiredness settles like a gentle fog, softening your energy.",
                    "Rest up, love! Short naps and light movement will lift your energy with care.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalReportCard() {
    return Container(
      decoration: BoxDecoration(
        color: kHomeCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan New Prescription/Report',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _scanReport,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: Text(
                  'Scan New Prescription/Report',
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHomePrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (_scannedReportOutput != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last Scanned Report:',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kHomeTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kHomePrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _scannedReportOutput!,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: kHomeTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kHomeTextColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: kHomeSecondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonIssueItem(String problem, String solution) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: kHomePrimaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: kHomeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              solution,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: kHomeSecondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ScanHistoryItem class can remain if you plan to use it for report history later
class ScanHistoryItem {
  final String name;
  final String type;
  final String contentSummary;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.name,
    required this.type,
    required this.contentSummary,
    required this.timestamp,
  });
}
