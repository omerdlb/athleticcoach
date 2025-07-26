import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_analysis_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

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
  late final DateTime _testSessionStartTime; // Test oturumu başlangıç zamanı
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    // Test oturumu başlangıç zamanını kaydet
    _testSessionStartTime = DateTime.now();
    _sessionId = const Uuid().v4(); // Benzersiz sessionId
    
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
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return false;
      }
      
      final result = double.tryParse(resultText);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} için geçerli bir sayı giriniz'),
            backgroundColor: AppTheme.errorColor,
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
      
      print('=== TEST SONUÇLARI HAZIRLANIYOR ===');
      print('Test: ${widget.selectedTest.name}');
      print('Sporcu Sayısı: ${widget.selectedAthletes.length}');
      
      for (final athlete in widget.selectedAthletes) {
        final resultText = _resultControllers[athlete.id]!.text.trim();
        final result = double.parse(resultText);
        final notes = _notesControllers[athlete.id]?.text.trim();
        
        print('--- Sporcu: ${athlete.name} ${athlete.surname} ---');
        print('Ham Sonuç: $resultText');
        print('Parse Edilen Sonuç: $result');
        print('Notlar: ${notes ?? 'Yok'}');
        print('Boy: ${athlete.height} cm');
        print('Kilo: ${athlete.weight} kg');
        print('Cinsiyet: ${athlete.gender}');
        print('Branş: ${athlete.branch}');
        
        results.add({
          'athlete': athlete,
          'result': result,
          'notes': notes,
        });
      }
      
      print('=== TOPLAM SONUÇLAR ===');
      print('Hazırlanan Sonuç Sayısı: ${results.length}');
      print('========================');

      // AI analizi ekranına git
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TestSessionAnalysisScreen(
              selectedTest: widget.selectedTest,
              results: results,
              sessionId: _sessionId, // yeni parametre
              testSessionStartTime: _testSessionStartTime, // yeni parametre
            ),
          ),
        );
      }
    } catch (e) {
      print('=== HATA ===');
      print('Analiz hazırlanırken hata: $e');
      print('============');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz hazırlanırken hata: $e'),
            backgroundColor: AppTheme.errorColor,
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
      // Test oturumu başlangıç zamanını kullan (tüm sonuçlar aynı zamanı kullanır)
      final testDate = _testSessionStartTime;

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
          aiAnalysis: null,
          sessionId: _sessionId,
        );

        await database.insertTestResult(testResult);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test sonuçları başarıyla kaydedildi!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Ana sayfaya dön
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonuçları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: AppTheme.gradientDecoration,
          ),
          Column(
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
                  widget.selectedTest.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kategori: ${widget.selectedTest.category}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sonuç Birimi: ${widget.selectedTest.resultUnit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedAthletes.length} sporcu için sonuç giriniz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
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
                
                    return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                      decoration: AppTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sporcu bilgisi
                        Row(
                          children: [
                            CircleAvatar(
                                  backgroundColor: athlete.gender == 'Kadın'
                                      ? AppTheme.femaleColor.withOpacity(0.2)
                                      : AppTheme.maleColor.withOpacity(0.2),
                                  child: Icon(
                                    athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                    color: athlete.gender == 'Kadın'
                                        ? AppTheme.femaleColor
                                        : AppTheme.maleColor,
                                    size: 24,
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
                                          color: AppTheme.primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    '${athlete.branch} • ${DateTime.now().year - athlete.birthDate.year} yaş',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.secondaryTextColor,
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
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                                labelStyle: TextStyle(color: AppTheme.primaryTextColor),
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
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                prefixIcon: Icon(Icons.note, color: AppTheme.primaryColor),
                                labelStyle: TextStyle(color: AppTheme.primaryTextColor),
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
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColorWithOpacity,
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
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _analyzeResults,
              icon: _isSaving 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.whiteTextColor,
                      ),
                    )
                  : Icon(Icons.auto_awesome, color: AppTheme.whiteTextColor),
              label: Text(
                _isSaving ? 'Analiz Ediliyor...' : 'AI Analizi Yap',
                style: TextStyle(color: AppTheme.whiteTextColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.whiteTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 