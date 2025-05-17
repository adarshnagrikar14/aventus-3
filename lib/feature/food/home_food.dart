import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final List<ScanHistoryItem> scanHistory = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header with title and subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Scanner',
                            style: GoogleFonts.lato(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade700,
                            ),
                          ),
                          Text(
                            'Scan food for nutrition information',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Camera/scanning area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Container(
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                      // Scanning overlay
                      if (isScanning)
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pink.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.pink.shade400,
                            ),
                          ),
                        ),

                      // Scanning button overlay
                      if (!isScanning)
                        GestureDetector(
                          onTap: () => _startScanning(),
                          child: Container(
                            width: 150,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade600,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Scan Food',
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Again',
                      color: Colors.pink.shade600,
                      onPressed: _startScanning,
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Erase',
                      color: Colors.grey.shade700,
                      onPressed: () {
                        setState(() {
                          scanResult = null;
                          isScanning = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Recent scans horizontal list
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Scans',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showHistoryPanel(),
                            child: Text(
                              'View All',
                              style: GoogleFonts.lato(
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          scanHistory.isEmpty
                              ? Center(
                                child: Text(
                                  'No recent scans',
                                  style: GoogleFonts.lato(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: scanHistory.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      scanHistory[scanHistory.length -
                                          1 -
                                          index];
                                  return Container(
                                    width: 120,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            scanResult =
                                                "${item.name} - ${item.calories} per 100g";
                                          });
                                          _showResultSheet();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.food_bank,
                                                size: 28,
                                                color: Colors.pink.shade400,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                item.name,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.lato(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                item.calories,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.lato(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
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
            ],
          ),

          // History button (moved to top-right instead of bottom-right)
          Positioned(
            top: 12,
            right: 16,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.history, color: Colors.pink.shade700, size: 22),
                    if (scanHistory.isNotEmpty)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            scanHistory.length.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showHistoryPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
    );
  }

  void _startScanning() {
    setState(() {
      isScanning = true;
    });

    // Simulate scanning
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isScanning = false;
        scanResult = "Apple - 52 calories per 100g";

        // Add to scan history
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
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Result title
                    Text(
                      'Scan Result',
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Result content
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scanResult ?? 'No result available',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Nutrition facts would go here
                          Text(
                            'Nutrition Facts:',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildNutritionItem('Calories', '52 kcal'),
                          _buildNutritionItem('Carbs', '14g'),
                          _buildNutritionItem('Protein', '0.3g'),
                          _buildNutritionItem('Fat', '0.2g'),
                          _buildNutritionItem('Fiber', '2.4g'),

                          const SizedBox(height: 30),

                          // Pregnancy recommendations
                          Text(
                            'Pregnancy Recommendations:',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Apples are a good source of fiber and vitamin C, which are beneficial during pregnancy. They help with digestion and boost immunity.',
                            style: GoogleFonts.lato(fontSize: 14),
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
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Title
                Text(
                  'Scan History',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ),

                // Clear history button
                if (scanHistory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        scanHistory.clear();
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),

                const SizedBox(height: 10),

                // History list
                Expanded(
                  child:
                      scanHistory.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'No scan history yet',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: scanHistory.length,
                            separatorBuilder:
                                (context, index) => Divider(
                                  color: Colors.grey.shade300,
                                  height: 1,
                                ),
                            itemBuilder: (context, index) {
                              final item =
                                  scanHistory[scanHistory.length -
                                      1 -
                                      index]; // Reverse order (newest first)
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.pink.shade100,
                                  child: Icon(
                                    Icons.food_bank,
                                    color: Colors.pink.shade700,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.calories} • ${_formatTimestamp(item.timestamp)}',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Simulate showing details for this history item
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
          Text(label, style: GoogleFonts.lato(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
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
