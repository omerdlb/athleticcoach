import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TestSessionResultsScreen extends StatefulWidget {
  final TestDefinitionModel selectedTest;
  final List<AthleteModel> selectedAthletes;

  const TestSessionResultsScreen({
    super.key,
    required this.selectedTest,
    required this.selectedAthletes,
  });

  @override
  State<TestSessionResultsScreen> createState() => _TestSessionResultsScreenState();
}

class _TestSessionResultsScreenState extends State<TestSessionResultsScreen> {
  final Map<String, TextEditingController> _resultControllers = {};
  final Map<String, TextEditingController> _notesControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Her sporcu için controller oluştur
    for (final athlete in widget.selectedAthletes) {
      _resultControllers[athlete.id] = TextEditingController();
      _notesControllers[athlete.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Controller'ları temizle
    for (final controller in _resultControllers.values) {
      controller.dispose();
    }
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateResults() {
    for (final athlete in widget.selectedAthletes) {
      final resultText = _resultControllers[athlete.id]?.text.trim();
      if (resultText == null || resultText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} için sonuç giriniz'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      final result = double.tryParse(resultText);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} için geçerli bir sayı giriniz'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _analyzeResults() async {
    if (!_validateResults()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Test sonuçlarını hazırla
      final List<Map<String, dynamic>> results = [];
      
      for (final athlete in widget.selectedAthletes) {
        final resultText = _resultControllers[athlete.id]!.text.trim();
        final result = double.parse(resultText);
        final notes = _notesControllers[athlete.id]?.text.trim();
        
        results.add({
          'athlete': athlete,
          'result': result,
          'notes': notes,
        });
      }

      // AI analizi ekranına git
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TestSessionAnalysisScreen(
              selectedTest: widget.selectedTest,
              results: results,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz hazırlanırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveResults() async {
    if (!_validateResults()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final database = AthleteDatabase();
      final testDate = DateTime.now();

      for (final athlete in widget.selectedAthletes) {
        final resultText = _resultControllers[athlete.id]!.text.trim();
        final result = double.parse(resultText);
        final notes = _notesControllers[athlete.id]?.text.trim();

        final testResult = TestResultModel(
          id: _generateId(),
          testId: widget.selectedTest.id,
          testName: widget.selectedTest.name,
          athleteId: athlete.id,
          athleteName: athlete.name,
          athleteSurname: athlete.surname,
          testDate: testDate,
          result: result,
          resultUnit: widget.selectedTest.resultUnit,
          notes: notes?.isNotEmpty == true ? notes : null,
        );

        await database.insertTestResult(testResult);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test sonuçları başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Ana sayfaya dön
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sonuçlar kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonuçları'),
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
                  widget.selectedTest.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                const SizedBox(height: 4),
                Text(
                  'Sonuç Birimi: ${widget.selectedTest.resultUnit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedAthletes.length} sporcu için sonuç giriniz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Sporcu sonuçları
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.selectedAthletes.length,
              itemBuilder: (context, index) {
                final athlete = widget.selectedAthletes[index];
                
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sporcu bilgisi
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                '${athlete.name[0]}${athlete.surname[0]}',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${athlete.name} ${athlete.surname}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${athlete.branch} • ${DateTime.now().year - athlete.birthDate.year} yaş',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Sonuç girişi
                        TextFormField(
                          controller: _resultControllers[athlete.id],
                          decoration: InputDecoration(
                            labelText: 'Test Sonucu (${widget.selectedTest.resultUnit})',
                            hintText: 'Örn: 12.5',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Sonuç giriniz';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Geçerli bir sayı giriniz';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Notlar
                        TextFormField(
                          controller: _notesControllers[athlete.id],
                          decoration: InputDecoration(
                            labelText: 'Notlar (İsteğe bağlı)',
                            hintText: 'Özel durumlar, gözlemler...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
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
                '${widget.selectedAthletes.length} sporcu için sonuç girildi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _analyzeResults,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isSaving ? 'Analiz Ediliyor...' : 'AI Analizi Yap'),
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