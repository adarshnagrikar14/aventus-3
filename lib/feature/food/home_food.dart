import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackathon/feature/food/image_scan_screen.dart';
import 'package:hackathon/feature/food/product/ui/product_screen.dart';
import 'package:hackathon/feature/logs/ui/meal_log_screen.dart';

class HomeFood extends StatefulWidget {
  const HomeFood({super.key});

  @override
  State<HomeFood> createState() => _HomeFoodState();
}

class _HomeFoodState extends State<HomeFood> {
  // Mock data for scan results - would be replaced with actual scan results
  String? scanResult;
  bool isScanning = false;

  // List to store scan history
  final List<ScanHistoryItem> scanHistory = [
    // Add some initial mock data for history tile visual
    ScanHistoryItem(
      name: "Apple",
      calories: "52 kcal",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ScanHistoryItem(
      name: "Banana",
      calories: "105 kcal",
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ]; // Keep history for the history tile

  // Define a professional color palette
  final Color _primaryColor = Colors.blueGrey.shade700;
  final Color _accentColor = Colors.teal.shade400; // Subtle accent
  final Color _backgroundColor = Colors.grey.shade100;
  final Color _cardBackgroundColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _secondaryTextColor = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Use defined background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 24.0,
        ), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                bottom: 28.0,
              ), // Increased bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nourishment Hub',
                    style: GoogleFonts.lato(
                      fontSize: 26, // Refined font size
                      fontWeight: FontWeight.bold,
                      color: _primaryColor, // Use primary color
                    ),
                  ),
                  const SizedBox(height: 6), // Adjusted spacing
                  Text(
                    'Track and understand your diet',
                    style: GoogleFonts.lato(
                      fontSize: 15, // Refined font size
                      color: _secondaryTextColor, // Use secondary text color
                    ),
                  ),
                ],
              ),
            ),

            // Grid of Tiles
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18, // Adjusted spacing
              mainAxisSpacing: 18, // Adjusted spacing
              children: <Widget>[
                _buildFeatureTile(
                  icon: Icons.restaurant_menu_outlined, // More relevant icon
                  title: 'Scan Meal',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImageScanScreen(),
                      ),
                    );
                  },
                  badgeCount: null, // No badge for this one
                ),
                _buildFeatureTile(
                  icon: Icons.qr_code_scanner_outlined, // More specific icon
                  title: 'Scan Barcode',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductScreen(),
                      ),
                    );
                  },
                  badgeCount: null,
                ),
                _buildFeatureTile(
                  icon: Icons.edit_note_outlined, // Icon for logging
                  title: 'Log Meal',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MealLogScreen(),
                      ),
                    );
                  },
                  badgeCount: null,
                ),
                _buildFeatureTile(
                  icon: Icons.manage_search_outlined, // Icon for history/search
                  title: 'Meal History',
                  onTap: _showHistoryPanel,
                  badgeCount:
                      scanHistory.isNotEmpty
                          ? scanHistory.length
                          : null, // Show badge only if items exist
                ),
              ],
            ),
            const SizedBox(height: 24), // Bottom spacing
          ],
        ),
      ),
    );
  }

  // Helper method to build a feature tile
  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Card(
      elevation: 0, // NO SHADOW
      color: _cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Slightly less rounded
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        ), // Subtle border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 42, // Adjusted icon size
                    color: _primaryColor, // Use primary color for icons
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -8, // Adjust badge position
                      right: -8, // Adjust badge position
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _accentColor, // Use accent color for badge
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _cardBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ), // Ensure badge is circular
                        child: Text(
                          badgeCount.toString(),
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 11, // Adjusted badge font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12), // Adjusted spacing
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14, // Adjusted title font size
                  fontWeight: FontWeight.w600, // Slightly bolder
                  color: _textColor, // Use text color
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startScanning() {
    setState(() {
      isScanning = true;
      scanResult = "Analyzing...";
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isScanning = false;
        scanResult = "Apple - 52 calories per 100g";
        scanHistory.add(
          ScanHistoryItem(
            name: "Apple",
            calories: "52 kcal",
            timestamp: DateTime.now(),
          ),
        );
      });
      _showResultSheet();
    });
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Important for custom shape and no shadow
      elevation: 0, // NO SHADOW for bottom sheet
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: _cardBackgroundColor, // Use card background color
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20), // Consistent rounding
                  ),
                  // NO SHADOW here
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      // Handle
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Scan Result',
                      style: GoogleFonts.lato(
                        fontSize: 20, // Adjusted font size
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _backgroundColor, // Use main background for contrast
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scanResult ?? 'No result available',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nutrition Facts:',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNutritionItem('Calories', '52 kcal'),
                          _buildNutritionItem('Carbs', '14g'),
                          _buildNutritionItem('Protein', '0.3g'),
                          _buildNutritionItem('Fat', '0.2g'),
                          _buildNutritionItem('Fiber', '2.4g'),
                          const SizedBox(height: 20),
                          Text(
                            'Pregnancy Recommendations:',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apples are a good source of fiber and vitamin C, which are beneficial during pregnancy. They help with digestion and boost immunity.',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showHistoryPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      elevation: 0, // NO SHADOW for history panel
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: _cardBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              // NO SHADOW here
            ),
            child: Column(
              children: [
                Padding(
                  // Handle
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Scan History',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                if (scanHistory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        scanHistory.clear();
                      });
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      size: 20,
                      color: _secondaryTextColor,
                    ),
                    label: Text(
                      'Clear All',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _secondaryTextColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _secondaryTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                Expanded(
                  child:
                      scanHistory.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons
                                      .receipt_long_outlined, // More appropriate icon
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No scan history yet',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: scanHistory.length,
                            separatorBuilder:
                                (context, index) => Divider(
                                  color:
                                      Colors.grey.shade200, // Lighter divider
                                  height: 1,
                                ),
                            itemBuilder: (context, index) {
                              final item =
                                  scanHistory[scanHistory.length - 1 - index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 8.0,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _accentColor.withOpacity(
                                    0.1,
                                  ),
                                  child: Icon(
                                    Icons.fastfood_outlined, // Food icon
                                    color: _accentColor,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: _textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.calories} • ${_formatTimestamp(item.timestamp)}',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: _secondaryTextColor,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: _secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      scanResult =
                                          "${item.name} - ${item.calories} per 100g";
                                    });
                                    _showResultSheet();
                                  },
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}, ${_formatTime(timestamp)}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Widget _buildNutritionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 14, color: _textColor)),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Class to represent a scan history item
class ScanHistoryItem {
  final String name;
  final String calories;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.name,
    required this.calories,
    required this.timestamp,
  });
}
