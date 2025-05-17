import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Mock data - replace with real data fetching
  int currentPregnancyWeek = 25; // Example week
  String babySize = "About the size of a cantaloupe";
  String babyWeight = "Around 1.5 pounds";
  String babyDevelopmentInfo = "Fingernails and toenails are growing...";
  String? scannedReportOutput; // Output from the report scanner

  void _show3DModel() {
    // TODO: Implement navigation or dialog to show 3D model
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('3D Baby Model', style: GoogleFonts.lato()),
            content: Text(
              'Imagine a beautiful 3D model here!',
              style: GoogleFonts.lato(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.lato()),
              ),
            ],
          ),
    );
  }

  void _scanReport() {
    // TODO: Implement image/document scanning logic
    // For now, simulate a scan delay and output
    setState(() {
      scannedReportOutput = "Analyzing...";
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        scannedReportOutput = """Report Analysis:
- Hemoglobin levels are within normal range (12.5 g/dL).
- Blood pressure is stable (110/70 mmHg).
- Urine test shows no abnormalities.
- Recommended follow-up in 4 weeks.
""";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the range of weeks to display around the current week
    const int weeksBefore = 4; // Show 4 weeks before
    const int weeksAfter =
        5; // Show 5 weeks after (total 10 circles including current)
    final int startWeek = currentPregnancyWeek - weeksBefore;
    final int endWeek = currentPregnancyWeek + weeksAfter;

    return Scaffold(
      // No AppBar here, as it's embedded in DashboardScreen
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Pregnancy Timeline Section
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 30,
                          color: Colors.teal.shade400,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Pregnancy Timeline',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Horizontal timeline of circles
                    SizedBox(
                      height: 80, // Adjust height based on circle size
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (endWeek - startWeek) + 1,
                        itemBuilder: (context, index) {
                          final week = startWeek + index;
                          // Ensure week is not less than 1 or more than ~40 (typical max)
                          if (week < 1 || week > 40)
                            return const SizedBox.shrink();

                          final isCurrentWeek = week == currentPregnancyWeek;
                          // Calculate size based on distance from current week
                          final distance = (week - currentPregnancyWeek).abs();
                          final double baseSize = 40.0; // Smallest circle size
                          final double maxSize = 60.0; // Largest circle size
                          final double size =
                              isCurrentWeek
                                  ? maxSize
                                  : maxSize -
                                      (maxSize - baseSize) *
                                          (distance / weeksBefore.toDouble())
                                              .clamp(
                                                0.0,
                                                1.0,
                                              ); // Scale down based on distance

                          return GestureDetector(
                            onTap: () {
                              // TODO: Implement action on tapping a week circle
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tapped Week $week'),
                                  duration: const Duration(milliseconds: 500),
                                ),
                              );
                              // Could update baby development info based on selected week
                              // setState(() {
                              //   currentPregnancyWeek = week; // if you want to jump
                              // });
                            },
                            child: Container(
                              width: size,
                              height: size,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isCurrentWeek
                                        ? Colors.pink.shade600
                                        : Colors.teal.shade300,
                                border:
                                    isCurrentWeek
                                        ? Border.all(
                                          color: Colors.pink.shade900,
                                          width: 3,
                                        )
                                        : null,
                                boxShadow: [
                                  if (isCurrentWeek)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  week.toString(),
                                  style: GoogleFonts.lato(
                                    color:
                                        isCurrentWeek
                                            ? Colors.white
                                            : Colors.teal.shade900,
                                    fontWeight:
                                        isCurrentWeek
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: isCurrentWeek ? 20 : 14,
                                  ),
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
            ),
            const SizedBox(height: 24),

            // Baby Photo and 3D Model Button Section
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias, // Clip the image to card shape
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Placeholder for Baby Photo (replace with actual image or Camera view)
                  Image.asset(
                    'assets/baby.jpg', // Use your baby image
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.child_care,
                                  size: 60,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Baby Scan Image Placeholder',
                                  style: GoogleFonts.lato(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),

                  // 3D Model Button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _show3DModel,
                      label: Text(
                        'View 3D',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.threed_rotation),
                      backgroundColor: Colors.pink.shade600,
                      foregroundColor: Colors.white,
                      elevation: 6.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Baby Development Status Section
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baby Development Status (Week $currentPregnancyWeek)',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusItem(
                      'Size',
                      babySize,
                      Icons.straighten_outlined,
                    ),
                    _buildStatusItem(
                      'Weight',
                      babyWeight,
                      Icons.monitor_weight_outlined,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      babyDevelopmentInfo,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    // TODO: Add more interactive elements like "Learn More" or week-by-week guide link
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Prescription and Report Scanner Section
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical Report Scanner',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _scanReport, // Call the scan function
                        icon: const Icon(Icons.camera_alt),
                        label: Text('Scan Report', style: GoogleFonts.lato()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Display scanned report output
                    if (scannedReportOutput != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(
                          scannedReportOutput!,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    // TODO: Add options to view previous reports or save reports
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Final spacing
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade400),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            // Use Expanded to prevent overflow for long text
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
            ),
          ),
        ],
      ),
    );
  }
}

// Class to represent a scan history item (can be reused/adapted from food scanner)
class ScanHistoryItem {
  final String name; // e.g., "Medical Report 2023-10-27"
  final String type; // e.g., "Prescription", "Blood Test"
  final String contentSummary; // e.g., "Hb: 12.5, BP: 110/70"
  final DateTime timestamp;

  ScanHistoryItem({
    required this.name,
    required this.type,
    required this.contentSummary,
    required this.timestamp,
  });
}
