import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_results_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class TestSessionSelectAthletesScreen extends StatefulWidget {
  final TestDefinitionModel selectedTest;

  const TestSessionSelectAthletesScreen({
    super.key,
    required this.selectedTest,
  });

  @override
  State<TestSessionSelectAthletesScreen> createState() => _TestSessionSelectAthletesScreenState();
}

class _TestSessionSelectAthletesScreenState extends State<TestSessionSelectAthletesScreen> {
  List<AthleteModel> allAthletes = [];
  List<AthleteModel> selectedAthletes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    try {
      final athletes = await AthleteDatabase().getAllAthletes();
      setState(() {
        allAthletes = athletes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sporcular yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _toggleAthleteSelection(AthleteModel athlete) {
    setState(() {
      if (selectedAthletes.contains(athlete)) {
        selectedAthletes.remove(athlete);
      } else {
        selectedAthletes.add(athlete);
      }
    });
  }

  void _continueToResults() {
    if (selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen en az bir sporcu seçin'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestSessionResultsScreen(
          selectedTest: widget.selectedTest,
          selectedAthletes: selectedAthletes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporcu Seç'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Test bilgisi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Test: ${widget.selectedTest.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedAthletes.length} sporcu seçildi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Sporcu listesi
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : allAthletes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz sporcu eklenmemiş',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Test oturumu başlatmak için önce sporcu ekleyin',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allAthletes.length,
                        itemBuilder: (context, index) {
                          final athlete = allAthletes[index];
                          final isSelected = selectedAthletes.contains(athlete);
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: athlete.gender == 'Kadın'
                                    ? AppTheme.femaleColor.withOpacity(0.2)
                                    : AppTheme.maleColor.withOpacity(0.2),
                                child: Icon(
                                  athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                  color: athlete.gender == 'Kadın'
                                      ? AppTheme.femaleColor
                                      : AppTheme.maleColor,
                                ),
                              ),
                              title: Text(
                                '${athlete.name} ${athlete.surname}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTextColor,
                                ),
                              ),
                              subtitle: Text(
                                '${athlete.branch} • ${athlete.birthDate.year}',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                              trailing: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.whiteTextColor,
                                      )
                                    : null,
                              ),
                              onTap: () => _toggleAthleteSelection(athlete),
                            ),
                          );
                        },
                      ),
          ),
          
          // Devam et butonu
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: selectedAthletes.isNotEmpty ? _continueToResults : null,
                icon: Icon(Icons.arrow_forward, color: AppTheme.whiteTextColor),
                label: Text(
                  'Devam Et (${selectedAthletes.length})',
                  style: TextStyle(
                    color: AppTheme.whiteTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.whiteTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 