import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_results_screen.dart';
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
          SnackBar(content: Text('Sporcular yüklenirken hata: $e')),
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
        const SnackBar(content: Text('Lütfen en az bir sporcu seçin')),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporcu Seç'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Test bilgisi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Test: ${widget.selectedTest.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kategori: ${widget.selectedTest.category}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seçilen Sporcu Sayısı: ${selectedAthletes.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Sporcu listesi
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allAthletes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz sporcu eklenmemiş',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Önce sporcu ekleyin',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: allAthletes.length,
                        itemBuilder: (context, index) {
                          final athlete = allAthletes[index];
                          final isSelected = selectedAthletes.contains(athlete);
                          
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? BorderSide(color: colorScheme.primary, width: 2)
                                  : BorderSide.none,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? colorScheme.primary : colorScheme.outline,
                                child: Icon(
                                  Icons.person,
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                ),
                              ),
                              title: Text(
                                '${athlete.name} ${athlete.surname}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Branş: ${athlete.branch}'),
                                  Text('Yaş: ${DateTime.now().year - athlete.birthDate.year}'),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleAthleteSelection(athlete),
                                activeColor: colorScheme.primary,
                              ),
                              onTap: () => _toggleAthleteSelection(athlete),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${selectedAthletes.length} sporcu seçildi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: selectedAthletes.isNotEmpty ? _continueToResults : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Devam Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 