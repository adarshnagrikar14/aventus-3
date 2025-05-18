import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackathon/feature/logs/cubit/meal_log_cubit.dart';
import 'package:hackathon/feature/logs/cubit/meal_log_state.dart';
import 'package:hackathon/feature/logs/data/meal_suggestions.dart';
import 'package:hackathon/feature/logs/data/models/meal_log_model.dart';
import 'package:http/http.dart' as http;

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  // Track which analysis types are selected
  final Set<String> _selectedAnalysisTypes = {
    'Nutritional Balance',
    'Suggestions',
    'Caloric Intake',
  };

  // Available analysis types for chips
  final List<String> _analysisTypes = [
    'Nutritional Balance',
    'Caloric Intake',
    'Suggestions',
    'Meal Timing',
    'Hydration',
    'Portion Size',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealLogCubit, MealLogState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Meal Log',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMealSection(
                      'Breakfast',
                      Icons.breakfast_dining,
                      state.breakfast,
                      MealType.breakfast,
                      context,
                    ),
                    _buildMealSection(
                      'Lunch',
                      Icons.lunch_dining,
                      state.lunch,
                      MealType.lunch,
                      context,
                    ),
                    _buildMealSection(
                      'Snacks',
                      Icons.cookie,
                      state.snacks,
                      MealType.snacks,
                      context,
                    ),
                    _buildMealSection(
                      'Dinner',
                      Icons.dinner_dining,
                      state.dinner,
                      MealType.dinner,
                      context,
                    ),
                  ],
                ),
              ),
              if (state.hasMinimumMeals) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Generate Insights',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Select max 3',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _analysisTypes.map((type) {
                              final isSelected = _selectedAnalysisTypes
                                  .contains(type);
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected:
                                    (selected) =>
                                        _updateSelectedChips(type, selected),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                selectedColor:
                                    Theme.of(context).colorScheme.primary,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed:
                            _selectedAnalysisTypes.isEmpty
                                ? null // Disable button if no chips selected
                                : () => _generateInsights(context),
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze Meals'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withOpacity(
                            0.5,
                          ),
                          disabledBackgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _updateSelectedChips(String type, bool selected) {
    setState(() {
      if (selected && _selectedAnalysisTypes.length < 3) {
        _selectedAnalysisTypes.add(type);
      } else if (!selected) {
        _selectedAnalysisTypes.remove(type);
      } else {
        // If trying to select more than 3, show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can select up to 3 analysis types'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Widget _buildMealSection(
    String title,
    IconData icon,
    List<FoodItem> items,
    MealType type,
    BuildContext context,
  ) {
    final colorMap = {
      MealType.breakfast: Colors.amber.shade700,
      MealType.lunch: Colors.green.shade600,
      MealType.snacks: Colors.purple.shade300,
      MealType.dinner: Colors.indigo.shade400,
    };

    final color = colorMap[type] ?? Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              title: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: () => _showAddMealSheet(context, type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                ),
              ),
            ),
          ),
          if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: Key('${type.name}_${item.name}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade100,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.red.shade700),
                  ),
                  onDismissed: (_) {
                    context.read<MealLogCubit>().removeMeal(type, index);
                  },
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    subtitle:
                        item.quantity != null
                            ? Text(
                              item.quantity!,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            )
                            : null,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        context.read<MealLogCubit>().removeMeal(type, index);
                      },
                    ),
                  ),
                );
              },
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No items added',
                    style: GoogleFonts.poppins(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, MealType type) {
    final suggestions = MealSuggestions.getSuggestions(type);
    final TextEditingController customMealController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (_, controller) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Add ${type.name.capitalize()} Item',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Add custom item',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: customMealController,
                            decoration: InputDecoration(
                              hintText: 'Enter food item',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            decoration: InputDecoration(
                              hintText: 'Quantity (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (customMealController.text.isNotEmpty) {
                                context.read<MealLogCubit>().addMeal(
                                  type,
                                  FoodItem(
                                    name: customMealController.text,
                                    quantity:
                                        quantityController.text.isEmpty
                                            ? null
                                            : quantityController.text,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Add Custom Item'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Suggestions',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                context.read<MealLogCubit>().addMeal(
                                  type,
                                  FoodItem(name: suggestion),
                                );
                                Navigator.pop(context);
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

  void _generateInsights(BuildContext context) {
    final state = context.read<MealLogCubit>().state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder:
                  (_, controller) => Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              'Meal Analysis',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: FutureBuilder(
                          future: _getGeminiInsights(state),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Analyzing your meals...',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: GoogleFonts.poppins(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            final analysisWidgets = <Widget>[];

                            // Only show selected analysis types
                            if (_selectedAnalysisTypes.contains(
                              'Nutritional Balance',
                            )) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Nutritional Balance',
                                  snapshot.data?['balance'] ?? '',
                                  snapshot.data?['metrics'],
                                ),
                              );
                            }

                            if (_selectedAnalysisTypes.contains(
                              'Caloric Intake',
                            )) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Caloric Intake',
                                  snapshot.data?['calories'] ?? '',
                                ),
                              );
                            }

                            if (_selectedAnalysisTypes.contains(
                              'Suggestions',
                            )) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Suggestions',
                                  snapshot.data?['suggestions'] ?? '',
                                ),
                              );
                            }

                            if (_selectedAnalysisTypes.contains(
                              'Meal Timing',
                            )) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Meal Timing',
                                  "Try to space your meals 3-4 hours apart for optimal digestion and energy levels.",
                                ),
                              );
                            }

                            if (_selectedAnalysisTypes.contains('Hydration')) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Hydration',
                                  "Remember to drink 8-10 glasses of water throughout the day alongside your meals.",
                                ),
                              );
                            }

                            if (_selectedAnalysisTypes.contains(
                              'Portion Size',
                            )) {
                              analysisWidgets.add(
                                _buildInsightSection(
                                  'Portion Size',
                                  "Your meals appear well-portioned. Keep protein to palm-size and vegetables to fist-size portions.",
                                ),
                              );
                            }

                            return ListView(
                              controller: controller,
                              padding: const EdgeInsets.all(16),
                              children: analysisWidgets,
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

  Widget _buildInsightSection(String title, String content, [String? metrics]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getIconForInsightType(title),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (title == 'Suggestions')
              _buildSuggestions(content)
            else
              _buildFormattedText(content),
            if (metrics != null && title == 'Nutritional Balance') ...[
              const SizedBox(height: 16),
              _buildNutritionChart(jsonDecode(metrics)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getIconForInsightType(String type) {
    switch (type) {
      case 'Nutritional Balance':
        return const Icon(Icons.balance, color: Colors.green);
      case 'Caloric Intake':
        return const Icon(Icons.local_fire_department, color: Colors.orange);
      case 'Suggestions':
        return const Icon(Icons.lightbulb_outline, color: Colors.amber);
      case 'Meal Timing':
        return const Icon(Icons.schedule, color: Colors.blue);
      case 'Hydration':
        return const Icon(Icons.water_drop, color: Colors.lightBlue);
      case 'Portion Size':
        return const Icon(Icons.straighten, color: Colors.purple);
      default:
        return const Icon(Icons.analytics, color: Colors.grey);
    }
  }

  Widget _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    final defaultStyle = GoogleFonts.poppins(
      color: Colors.black87,
      fontSize: 14,
    );

    final boldStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      fontSize: 14,
    );

    for (final Match match in exp.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text
                .substring(lastIndex, match.start)
                .replaceAll('FontWeight.w400', ''),
            style: defaultStyle,
          ),
        );
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1)?.replaceAll('FontWeight.w400', '') ?? '',
          style: boldStyle,
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex).replaceAll('FontWeight.w400', ''),
          style: defaultStyle,
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(style: defaultStyle, children: spans),
    );
  }

  Widget _buildNutritionChart(Map<String, dynamic> metrics) {
    // Standard daily values (in percentage)
    const standardValues = {
      'protein': 100.0, // 100% is the target
      'carbs': 100.0,
      'fats': 100.0,
    };

    return Column(
      children: [
        _buildProgressBar(
          'Protein',
          (metrics['protein'] ?? 0).toDouble(),
          standardValues['protein']!,
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildProgressBar(
          'Carbs',
          (metrics['carbs'] ?? 0).toDouble(),
          standardValues['carbs']!,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildProgressBar(
          'Fats',
          (metrics['fats'] ?? 0).toDouble(),
          standardValues['fats']!,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    String label,
    double value,
    double standard,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Standard value indicator
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        (standard / 100 * 2) - 1, // Convert to -1 to 1 range
                        0,
                      ),
                      child: Container(
                        width: 2,
                        color: Colors.black54,
                        height: 16,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${value.round()}%',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 80),
          child: Text(
            value < standard
                ? 'Need ${(standard - value).round()}% more'
                : value > standard
                ? '${(value - standard).round()}% excess'
                : 'Optimal level',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color:
                  value == standard
                      ? Colors.green
                      : value < standard
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(String suggestions) {
    // Convert string array to actual list
    final suggestionList =
        suggestions
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          suggestionList
              .map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Future<Map<String, String>> _getGeminiInsights(MealLogState state) async {
    const apiKey = 'AIzaSyB4kcWMemFLQ8dkJqgdTsOmN1NN5pwO30o';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

    try {
      final prompt = '''
      System: You are a nutritionist analyzing a person's daily meal log. Provide concise insights (max 2-3 lines each) in the following JSON format:
      {
        "balance": "Brief analysis with key nutrients marked in **bold**",
        "calories": "Estimated total calories: **X kcal**. Brief breakdown: breakfast(**X**), lunch(**X**), snacks(**X**), dinner(**X**)",
        "suggestions": "3 bullet points with improvements",
        "metrics": {
          "protein": X,
          "carbs": X,
          "fats": X,
          "totalCalories": X
        }
      }
      
      User's meals for today:
      Breakfast: ${_formatMeals(state.breakfast)}
      Lunch: ${_formatMeals(state.lunch)}
      Snacks: ${_formatMeals(state.snacks)}
      Dinner: ${_formatMeals(state.dinner)}
      ''';

      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates'][0]['content']['parts'][0]['text']
                as String;

        final startIndex = text.indexOf('{');
        final endIndex = text.lastIndexOf('}') + 1;
        final jsonStr = text.substring(startIndex, endIndex);

        final Map<String, dynamic> insights = jsonDecode(jsonStr);

        return {
          'balance':
              insights['balance']?.toString() ??
              'No balance analysis available',
          'calories':
              insights['calories']?.toString() ??
              'No caloric analysis available',
          'suggestions':
              insights['suggestions']?.toString() ?? 'No suggestions available',
          'metrics': jsonEncode(insights['metrics'] ?? {}),
        };
      }

      throw Exception('Failed to get insights');
    } catch (e, stackTrace) {
      print('Error getting insights: $e');
      print('Stack trace: $stackTrace');
      return {
        'balance': 'Error analyzing nutritional balance',
        'calories': 'Error calculating calories',
        'suggestions': 'Unable to generate suggestions',
        'metrics': '{}',
      };
    }
  }

  String _formatMeals(List<FoodItem> items) {
    if (items.isEmpty) return 'No meals logged';
    return items
        .map(
          (item) =>
              '${item.name}${item.quantity != null ? ' (${item.quantity})' : ''}',
        )
        .join(', ');
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
