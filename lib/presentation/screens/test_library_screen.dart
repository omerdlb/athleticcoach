import 'package:athleticcoach/data/predefined_data.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/presentation/screens/test_protocol_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class TestLibraryScreen extends StatefulWidget {
  const TestLibraryScreen({super.key});

  @override
  State<TestLibraryScreen> createState() => _TestLibraryScreenState();
}

class _TestLibraryScreenState extends State<TestLibraryScreen> {
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
    final filteredTests = _selectedCategory == 'Tümü'
        ? predefinedTests
        : predefinedTests.where((t) => t.category == _selectedCategory).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Kütüphanesi'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
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
                  label: Text(
                    cat, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.getResponsiveFontSize(context, 14),
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.whiteTextColor : AppTheme.primaryColor,
                    fontSize: AppTheme.getResponsiveFontSize(context, 14),
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor.withOpacity(0.07), AppTheme.cardBackgroundColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColorWithOpacity,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 32),
                    title: Text(
                      test.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.getResponsiveFontSize(context, 18),
                        letterSpacing: 0.2,
                        height: 1.2,
                        color: AppTheme.primaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              test.category,
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: AppTheme.getResponsiveFontSize(context, 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 20, color: AppTheme.primaryColor),
                    onTap: () {
                      _addToRecentTests(test);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TestProtocolScreen(test: test),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToRecentTests(TestDefinitionModel test) async {
    try {
      final recentTest = RecentTestModel(
        testName: test.name,
        athleteName: '', // Sporcu ismi kullanılmıyor
        testDate: DateTime.now().toString().split(' ')[0], // Bugünün tarihi
        viewedAt: DateTime.now(),
      );
      
      await AthleteDatabase().addRecentTest(recentTest);
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Recent test eklenirken hata: $e');
    }
  }
} 