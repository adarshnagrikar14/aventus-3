import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackathon/feature/food/product/data/models/detailed_product_model.dart';
import 'package:hackathon/feature/food/product/data/repo/product_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/cubit/product_cubit.dart';

// Define a modern color palette
const Color kPrimaryColor = Color(0xFF4CAF50); // A vibrant green
const Color kAccentColor = Color(0xFFFFC107); // A warm yellow
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light grey for background
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kErrorColor = Color(0xFFD32F2F);

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late MobileScannerController controller;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _checkPermission();
    context.read<ProductCubit>().reset();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void _startScanning() {
    setState(() => isScanning = true);
    controller = MobileScannerController();
    context.read<ProductCubit>().reset();
  }

  void _showNutrientsSheet(
    BuildContext context,
    Map<String, dynamic> nutrients,
  ) {
    print('Nutrients: $nutrients');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: nutrients.length,
                          itemBuilder: (context, index) {
                            final entry = nutrients.entries.elementAt(index);
                            return ListTile(
                              title: Text(
                                entry.key.split('_').join(' ').toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Text(
                                entry.value.toString(),
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showAllergensSheet(BuildContext context, List<String> allergens) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Allergens',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: allergens.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text(
                          allergens[index],
                          style: GoogleFonts.poppins(),
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

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        context.read<ProductCubit>().reset();
        return true;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: kPrimaryColor),
          title: Text(
            'Scan Product',
            style: GoogleFonts.poppins(
              color: kTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (isScanning)
              IconButton(
                icon: Icon(
                  controller.torchEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: kPrimaryColor,
                ),
                onPressed: () => controller.toggleTorch(),
              ),
          ],
        ),
        body: BlocConsumer<ProductCubit, ProductState>(
          listener: (context, state) {
            if (state is ProductError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is ProductLoaded) {
              _stopScanning();
            }
          },
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              );
            }
            if (state is ProductLoaded) {
              return _buildProductInfo(state);
            }
            return _buildScanner(context);
          },
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    if (!isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 80,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Scan?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Point your camera at a product\'s barcode to get instant nutritional insights and details.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: kSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _startScanning,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Start Scanning'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null && code.isNotEmpty && context.mounted) {
                controller.stop();
                context.read<ProductCubit>().scanProduct(code);
                break;
              }
            }
          },
        ),
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          child: const Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 2),
                    bottom: BorderSide(color: Colors.white, width: 2),
                    left: BorderSide(color: Colors.white, width: 2),
                    right: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(ProductLoaded state) {
    final basic = state.basicProduct;
    final detailed = state.detailedProduct;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: Image.network(
                      basic.imageUrl!,
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                      errorBuilder:
                          (_, __, ___) => Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 64,
                              color: kSecondaryTextColor,
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  basic.name,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                if (basic.brands != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    basic.brands!,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Scores Row
                _buildScoresSection(detailed),

                const SizedBox(height: 16),

                // Nutrition Facts Card
                _buildNutritionCard(detailed.nutrients),
                const SizedBox(height: 16),

                // Nutrient Levels
                _buildNutrientLevelsCard(detailed.nutrientLevels),
                const SizedBox(height: 16),
                // Ingredients
                if (detailed.ingredients.isNotEmpty)
                  _buildInteractiveListTile(
                    title: 'Ingredients',
                    items: detailed.ingredients,
                    icon: Icons.format_list_bulleted_rounded,
                    isExpandable: true,
                  ),

                // Allergens Warning
                const SizedBox(height: 16),
                if (detailed.allergens.isNotEmpty) ...[
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: kErrorColor.withOpacity(0.5)),
                    ),
                    color: kErrorColor.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: kErrorColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Potential Allergens',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: kErrorColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children:
                                detailed.allergens.map((allergen) {
                                  return Chip(
                                    label: Text(
                                      allergen,
                                      style: GoogleFonts.poppins(
                                        color: kErrorColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: kErrorColor.withOpacity(
                                      0.1,
                                    ),
                                    side: BorderSide(
                                      color: kErrorColor.withOpacity(0.3),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Additional Information
                _buildInfoSection('Product Details', [
                  if (basic.quantity != null)
                    InfoRow('Quantity', basic.quantity!),
                  if (detailed.servingSize != null)
                    InfoRow('Serving Size', detailed.servingSize!),
                  if (detailed.packaging.isNotEmpty)
                    InfoRow('Packaging', detailed.packaging.join(', ')),
                  if (detailed.origins != null)
                    InfoRow('Origin', detailed.origins!),
                  if (detailed.categories.isNotEmpty)
                    InfoRow('Categories', detailed.categories.join(', ')),
                ]),

                const SizedBox(height: 24),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _startScanning,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Another Product'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(DetailedProductModel detailed) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Scores',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreIndicator(
                    'Nutri-Score',
                    detailed.nutriScore?.toUpperCase() ?? 'N/A',
                    _getNutriScoreDescription(detailed.nutriScore),
                    _getNutriScoreColor(detailed.nutriScore),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildNovaScore(detailed.novaGroup)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScoreIndicator(
                    'Eco-Score',
                    detailed.ecoscore?.toUpperCase() ?? 'N/A',
                    _getEcoScoreDescription(detailed.ecoscore),
                    _getEcoScoreColor(detailed.ecoscore),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(
    String title,
    String score,
    String description,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 2.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              score,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: kTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: GoogleFonts.poppins(fontSize: 12, color: kSecondaryTextColor),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNovaScore(String? novaGroup) {
    final group = int.tryParse(novaGroup ?? '') ?? 0;
    final descriptions = [
      'N/A',
      'Unprocessed',
      'Processed Culinary',
      'Processed Foods',
      'Ultra-processed',
    ];
    final colors = [
      Colors.grey.shade400, // N/A
      Colors.green.shade600, // Unprocessed
      Colors.lightGreen.shade600, // Processed Culinary
      Colors.orange.shade600, // Processed Foods
      Colors.red.shade600, // Ultra-processed
    ];

    // Ensure group index is within bounds
    final int validGroup = group.clamp(0, descriptions.length - 1);

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors[validGroup].withOpacity(0.15),
            border: Border.all(color: colors[validGroup], width: 2.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NOVA',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors[validGroup],
                ),
              ),
              Text(
                validGroup.toString(), // Display the validated group
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors[validGroup],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Food Processing',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: kTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          descriptions[validGroup],
          style: GoogleFonts.poppins(fontSize: 12, color: kSecondaryTextColor),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getNutriScoreDescription(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return 'Excellent nutritional quality';
      case 'b':
        return 'Good nutritional quality';
      case 'c':
        return 'Average nutritional quality';
      case 'd':
        return 'Poor nutritional quality';
      case 'e':
        return 'Unhealthy nutritional quality';
      default:
        return 'Not available';
    }
  }

  String _getEcoScoreDescription(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return 'Very low environmental impact';
      case 'b':
        return 'Low environmental impact';
      case 'c':
        return 'Moderate environmental impact';
      case 'd':
        return 'High environmental impact';
      case 'e':
        return 'Very high environmental impact';
      default:
        return 'Not available';
    }
  }

  Color _getNutriScoreColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return Colors.green.shade600;
      case 'b':
        return Colors.lightGreen.shade600;
      case 'c':
        return Colors.yellow.shade700;
      case 'd':
        return Colors.orange.shade600;
      case 'e':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getEcoScoreColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return Colors.green.shade600;
      case 'b':
        return Colors.lightGreen.shade600;
      case 'c':
        return Colors.yellow.shade700;
      case 'd':
        return Colors.orange.shade600;
      case 'e':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildNutritionCard(NutrimentsModel nutrients) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Facts',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildMainNutrients(nutrients),
            const Divider(),
            _buildMineralsSection(nutrients),
            if (nutrients.transFat != null) ...[
              const Divider(),
              _buildFatTypes(nutrients),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainNutrients(NutrimentsModel nutrients) {
    return Column(
      children: [
        _buildNutrientRow(
          'Energy',
          '${nutrients.energy} kcal',
          isHighlighted: true,
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        _buildNutrientBarRow(
          'Proteins',
          nutrients.proteins,
          50, // Example RDA, adjust as needed
          Colors.green.shade600,
          Icons.fitness_center_rounded,
        ),
        _buildNutrientBarRow(
          'Carbohydrates',
          nutrients.carbohydrates,
          300, // Example RDA, adjust as needed
          Colors.orange.shade600,
          Icons.bakery_dining_rounded,
        ),
        _buildNutrientBarRow(
          'Fat',
          nutrients.fat,
          70, // Example RDA, adjust as needed
          Colors.red.shade600,
          Icons.fastfood_rounded,
        ),
        _buildNutrientBarRow(
          'Fiber',
          nutrients.fiber,
          30, // Example RDA, adjust as needed
          Colors.brown.shade600,
          Icons.eco_rounded,
        ),
        _buildNutrientBarRow(
          'Sugars',
          nutrients.sugars,
          25, // Example WHO recommended limit
          Colors.pink.shade400,
          Icons.cake_rounded,
        ),
      ],
    );
  }

  Widget _buildMineralsSection(NutrimentsModel nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minerals & Vitamins',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 10),
        _buildMineralRow(
          'Calcium',
          '${nutrients.calcium?.toStringAsFixed(1) ?? 'N/A'}mg',
          Icons.grain_rounded, // Placeholder icon
        ),
        _buildMineralRow(
          'Iron',
          '${nutrients.iron?.toStringAsFixed(1) ?? 'N/A'}mg',
          Icons.opacity_rounded, // Placeholder icon
        ),
        _buildMineralRow(
          'Sodium',
          '${nutrients.sodium?.toStringAsFixed(1) ?? 'N/A'}mg',
          Icons.water_drop_rounded, // Placeholder icon
        ),
      ],
    );
  }

  Widget _buildFatTypes(NutrimentsModel nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fat Types',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 10),
        _buildNutrientRow(
          'Saturated Fat',
          '${nutrients.saturatedFat?.toStringAsFixed(1) ?? 'N/A'}g',
          icon: Icons.warning_amber_rounded,
          iconColor:
              (nutrients.saturatedFat ?? 0) > 5
                  ? kErrorColor // Highlight if high
                  : kSecondaryTextColor,
        ),
        if (nutrients.transFat != null)
          _buildNutrientRow(
            'Trans Fat',
            '${nutrients.transFat?.toStringAsFixed(1) ?? 'N/A'}g',
            textColor: (nutrients.transFat ?? 0) > 0 ? kErrorColor : null,
            icon: Icons.dangerous_rounded,
            iconColor:
                (nutrients.transFat ?? 0) > 0
                    ? kErrorColor
                    : kSecondaryTextColor,
          ),
      ],
    );
  }

  Widget _buildNutrientBarRow(
    String label,
    double value,
    double maxValue,
    Color color,
    IconData icon,
  ) {
    final percentage = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: kTextColor,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}g',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  fontSize: 15,
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
        ],
      ),
    );
  }

  Widget _buildMineralRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kSecondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: kSecondaryTextColor,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: kTextColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? kPrimaryColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? kTextColor,
                fontSize: isHighlighted ? 17 : 15,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: textColor ?? kTextColor,
              fontSize: isHighlighted ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }

  void _stopScanning() {
    setState(() => isScanning = false);
    controller.dispose();
  }

  Widget _buildNutrientLevelsCard(NutrientLevels levels) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrient Levels',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientLevelIndicator('Fat', levels.fat),
            _buildNutrientLevelIndicator('Saturated Fat', levels.saturatedFat),
            _buildNutrientLevelIndicator('Sugars', levels.sugars),
            _buildNutrientLevelIndicator('Salt', levels.salt),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientLevelIndicator(String nutrient, String level) {
    final colors = {
      'low': Colors.green.shade600,
      'moderate': Colors.orange.shade600,
      'high': Colors.red.shade600,
      'unknown': Colors.grey.shade400,
    };
    final levelLowerCase = level.toLowerCase();
    final displayColor = colors[levelLowerCase] ?? Colors.grey.shade400;

    final Map<String, IconData> icons = {
      'fat': Icons.opacity_rounded, // Example, choose appropriate icons
      'saturated fat': Icons.warning_amber_rounded,
      'sugars': Icons.cake_rounded,
      'salt': Icons.water_drop_outlined,
    };
    final nutrientLowerCase = nutrient.toLowerCase();
    final displayIcon = icons[nutrientLowerCase] ?? Icons.info_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(displayIcon, size: 20, color: displayColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nutrient,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: kTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: displayColor.withOpacity(0.5)),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value:
                  levelLowerCase == 'low'
                      ? 0.25
                      : levelLowerCase == 'moderate'
                      ? 0.6
                      : levelLowerCase == 'high'
                      ? 0.9
                      : 0.05, // small value for unknown
              backgroundColor: Colors.grey[300],
              color: displayColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<InfoRow> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveListTile({
    required String title,
    required List<String> items,
    required IconData icon,
    bool isExpandable = false,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent), // Modern look
        child: ExpansionTile(
          leading: Icon(icon, color: iconColor ?? kPrimaryColor, size: 26),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18, // Slightly larger for section titles
              color: kTextColor,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ).copyWith(top: 0),
          children: [
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    items.map((item) => _buildIngredientChip(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(String ingredient) {
    // Define common allergens for highlighting
    final commonAllergens = {
      'milk': Colors.blue.shade100,
      'egg': Colors.yellow.shade100,
      'nuts': Colors.brown.shade100,
      'peanut': Colors.deepOrange.shade100,
      'soy': Colors.green.shade100,
      'wheat': Colors.orange.shade100,
      'gluten': Colors.orange.shade200, // Added gluten
      'fish': Colors.blue.shade200,
      'shellfish': Colors.pink.shade100,
      'sesame': Colors.teal.shade100, // Added sesame
      'sulphites': Colors.purple.shade100, // Added sulphites
      'mustard': Colors.amber.shade100, // Added mustard
    };

    // Check if ingredient contains any allergen
    String lowerIngredient = ingredient.toLowerCase();
    final allergenEntry = commonAllergens.entries.firstWhere(
      (entry) => lowerIngredient.contains(entry.key),
      orElse: () => MapEntry('none', Colors.grey.shade200),
    );

    final isAllergen = allergenEntry.key != 'none';
    final chipColor = isAllergen ? allergenEntry.value : Colors.grey.shade200;
    final textColor = isAllergen ? Colors.black87 : kSecondaryTextColor;
    final fontWeight = isAllergen ? FontWeight.w600 : FontWeight.normal;

    return Chip(
      label: Text(
        ingredient.cleanupLabel, // Use the extension method
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
      backgroundColor: chipColor,
      side:
          isAllergen
              ? BorderSide(color: chipColor.darken(15), width: 1.5)
              : BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label.isNotEmpty ? label.cleanupLabel : 'N/A',
              style: GoogleFonts.poppins(
                color: kSecondaryTextColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: GoogleFonts.poppins(color: kTextColor, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// Add these extension methods for better visual indicators
extension ColorX on Color {
  /// Darkens a color by [percent] (between 0 and 100).
  Color darken([int percent = 10]) {
    assert(0 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }

  /// Lightens a color by [percent] (between 0 and 100).
  Color lighten([int percent = 10]) {
    assert(0 <= percent && percent <= 100);
    final p = percent / 100;
    return Color.fromARGB(
      alpha,
      red + ((255 - red) * p).round(),
      green + ((255 - green) * p).round(),
      blue + ((255 - blue) * p).round(),
    );
  }
}

extension StringX on String {
  String get cleanupLabel {
    if (isEmpty) return 'N/A';
    return split(RegExp(r'[\s_]+')) // Split by space or underscore
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ')
        .replaceAllMapped(
          RegExp(r':\s*([a-z])'),
          (match) => ': ${match.group(1)!.toUpperCase()}',
        ); // Capitalize after colon
  }
}
