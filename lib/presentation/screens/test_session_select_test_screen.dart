import 'package:athleticcoach/data/predefined_data.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_select_athletes_screen.dart';
import 'package:flutter/material.dart';

class TestSessionSelectTestScreen extends StatefulWidget {
  const TestSessionSelectTestScreen({super.key});

  @override
  State<TestSessionSelectTestScreen> createState() => _TestSessionSelectTestScreenState();
}

class _TestSessionSelectTestScreenState extends State<TestSessionSelectTestScreen> {
  final List<String> _categories = [
    'Tümü',
    'Aerobik',
    'Anaerobik',
    'Çeviklik',
    'Patlayıcı Güç',
    'Sürat',
    'Esneklik',
    'Dayanıklılık',
    'İndirekt (Submaksimal)',
  ];
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredTests = _selectedCategory == 'Tümü'
        ? predefinedTests
        : predefinedTests.where((t) => t.category == _selectedCategory).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Seç'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Kategori filtre çubuğu
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat, style: TextStyle(fontWeight: FontWeight.w600)),
                  selected: selected,
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.primary.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : colorScheme.primary,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: selected ? 4 : 0,
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTests.length,
        itemBuilder: (context, index) {
                final test = filteredTests[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TestSessionSelectAthletesScreen(
                          selectedTest: test,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: index % 2 == 0
                            ? [colorScheme.primary.withOpacity(0.08), Colors.white]
                            : [colorScheme.secondary.withOpacity(0.08), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.fitness_center, color: colorScheme.primary, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        test.category,
                                        style: TextStyle(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        test.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                  Text(
                    test.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF6366F1)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 