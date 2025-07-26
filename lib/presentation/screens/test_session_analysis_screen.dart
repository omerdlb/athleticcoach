import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/data/models/team_analysis_model.dart'; // Takım analizi modeli
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TestSessionAnalysisScreen extends StatefulWidget {
  final TestDefinitionModel selectedTest;
  final List<Map<String, dynamic>> results;
  final String sessionId;
  final DateTime testSessionStartTime;

  const TestSessionAnalysisScreen({
    super.key,
    required this.selectedTest,
    required this.results,
    required this.sessionId,
    required this.testSessionStartTime,
  });

  @override
  State<TestSessionAnalysisScreen> createState() => _TestSessionAnalysisScreenState();
}

class _TestSessionAnalysisScreenState extends State<TestSessionAnalysisScreen> {
  final Map<String, bool> _isAnalyzing = {};
  final Map<String, String> _analysisResults = {};
  bool _isSaving = false;
  late final DateTime _testSessionStartTime;

  @override
  void initState() {
    super.initState();
    _testSessionStartTime = DateTime.now();
    
    // Her sporcu için analiz durumunu başlat
    for (final result in widget.results) {
      final athlete = result['athlete'] as AthleteModel;
      _isAnalyzing[athlete.id] = false;
      _analysisResults[athlete.id] = '';
    }
    
    // Tüm sonuçları otomatik olarak analiz et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeAllResults();
    });
  }

  Future<void> _analyzeAthleteResult(AthleteModel athlete, double result, String? notes) async {
    setState(() {
      _isAnalyzing[athlete.id] = true;
    });

    try {
      final age = DateTime.now().year - athlete.birthDate.year;
      
      // Debug bilgileri
      print('=== ANALİZ BAŞLATILIYOR ===');
      print('Sporcu ID: ${athlete.id}');
      print('Sporcu: ${athlete.name} ${athlete.surname}');
      print('Yaş: $age');
      print('Cinsiyet: ${athlete.gender}');
      print('Branş: ${athlete.branch}');
      print('Boy: ${athlete.height} cm');
      print('Kilo: ${athlete.weight} kg');
      print('Test: ${widget.selectedTest.name}');
      print('Sonuç: $result ${widget.selectedTest.resultUnit}');
      print('Notlar: ${notes ?? 'Yok'}');
      print('==========================');
      
      final analysis = await GeminiService.generateDetailedAnalysis(
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        age: age,
        gender: athlete.gender,
        branch: athlete.branch,
        height: athlete.height,
        weight: athlete.weight,
        testName: widget.selectedTest.name,
        result: result,
        resultUnit: widget.selectedTest.resultUnit,
        notes: notes,
      );
      
      if (mounted && analysis != null) {
        print('=== ANALİZ TAMAMLANDI ===');
        print('Sporcu: ${athlete.name} ${athlete.surname}');
        print('Analiz Uzunluğu: ${analysis.length} karakter');
        print('========================');
        
        // API aşırı yüklü hatası kontrolü
        if (analysis.contains('API aşırı yüklü') || analysis.contains('overloaded')) {
          setState(() {
            _analysisResults[athlete.id] = 'API aşırı yüklü. Lütfen birkaç dakika sonra tekrar deneyin.';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${athlete.name} ${athlete.surname} - API aşırı yüklü, daha sonra tekrar deneyin'),
                backgroundColor: AppTheme.warningColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        setState(() {
          _analysisResults[athlete.id] = analysis;
        });
        
        // Analiz tamamlandığında otomatik kaydet
        await _saveSingleResult(athlete, result, notes, analysis);
      } else {
        print('=== ANALİZ HATASI ===');
        print('Sporcu: ${athlete.name} ${athlete.surname}');
        print('Analiz null döndü!');
        print('=====================');
        
        setState(() {
          _analysisResults[athlete.id] = 'Analiz alınamadı. Lütfen tekrar deneyin.';
        });
      }
    } catch (e) {
      print('=== ANALİZ EXCEPTION ===');
      print('Sporcu: ${athlete.name} ${athlete.surname}');
      print('Hata: $e');
      print('=======================');
      
      if (mounted) {
        setState(() {
          _analysisResults[athlete.id] = 'Analiz sırasında hata oluştu: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - Analiz hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing[athlete.id] = false;
        });
      }
    }
  }

  Future<void> _saveSingleResult(AthleteModel athlete, double result, String? notes, String analysis) async {
    try {
      final database = AthleteDatabase();
      final testDate = _testSessionStartTime;

      final testResultModel = TestResultModel(
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
        aiAnalysis: analysis.isNotEmpty ? analysis : null,
        sessionId: widget.sessionId,
      );

      await database.insertTestResult(testResultModel);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - Analiz kaydedildi!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - Kaydetme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _analyzeAllResults() async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (final result in widget.results) {
        final athlete = result['athlete'] as AthleteModel;
        final testResult = result['result'] as double;
        final notes = result['notes'] as String?;
        
        await _analyzeAthleteResult(athlete, testResult, notes);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Takım analizi - sadece birden fazla sporcu varsa
      if (widget.results.length > 1) {
        await _generateTeamAnalysis();
      }

      // Tüm analizler tamamlandığında sadece bilgi mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tüm analizler tamamlandı ve kaydedildi!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
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

  Future<void> _generateTeamAnalysis() async {
    try {
      print('=== TAKIM ANALİZİ BAŞLATILIYOR ===');
      print('Sporcu Sayısı: ${widget.results.length}');
      print('Test: ${widget.selectedTest.name}');
      print('===============================');

      // Takım analizi için veri hazırla
      final teamResults = widget.results.map((result) {
        final athlete = result['athlete'] as AthleteModel;
        final testResult = result['result'] as double;
        final age = DateTime.now().year - athlete.birthDate.year;
        
        return {
          'athlete': {
            'name': athlete.name,
            'surname': athlete.surname,
            'age': age,
            'gender': athlete.gender,
          },
          'result': testResult,
          'unit': widget.selectedTest.resultUnit,
        };
      }).toList();

      final teamAnalysis = await GeminiService.generateTeamAnalysis(
        results: teamResults,
        testName: widget.selectedTest.name,
      );

      if (teamAnalysis != null && teamAnalysis.isNotEmpty) {
        print('=== TAKIM ANALİZİ TAMAMLANDI ===');
        print('Analiz Uzunluğu: ${teamAnalysis.length} karakter');
        print('==============================');

        // Takım analizini veritabanına kaydet
        final database = AthleteDatabase();
        final teamAnalysisModel = TeamAnalysisModel(
          id: null, // id null olabilir (otomatik artacak)
          testSessionId: _generateId(), // String olarak
          testName: widget.selectedTest.name,
          analysis: teamAnalysis,
          createdAt: DateTime.now(),
          participantCount: widget.results.length,
        );

        await database.addTeamAnalysis(teamAnalysisModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Takım analizi tamamlandı ve kaydedildi!'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('=== TAKIM ANALİZİ HATASI ===');
        print('Analiz null döndü!');
        print('===========================');
      }
    } catch (e) {
      print('=== TAKIM ANALİZİ EXCEPTION ===');
      print('Hata: $e');
      print('==============================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takım analizi sırasında hata: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analiz'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: AppTheme.whiteTextColor,
              size: 24,
            ),
            tooltip: 'Ana Menüye Dön',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
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
                      '${widget.results.length} sporcu için AI analizi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
          
              // Analiz sonuçları
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.results.length,
                  itemBuilder: (context, index) {
                    final result = widget.results[index];
                    final athlete = result['athlete'] as AthleteModel;
                    final testResult = result['result'] as double;
                    final notes = result['notes'] as String?;
                    final isAnalyzing = _isAnalyzing[athlete.id] ?? false;
                    final hasAnalysis = _analysisResults[athlete.id]?.isNotEmpty == true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
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
                                        'Sonuç: $testResult ${widget.selectedTest.resultUnit}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAnalyzing)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                else if (hasAnalysis)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            
                            if (hasAnalysis) ...[
                              const SizedBox(height: 16),
                              
                              // AI Analizi - Tek Kart
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Başlık
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'AI Performans Analizi',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Tam analiz metni
                                    Text(
                                      _analysisResults[athlete.id] ?? 'Analiz bulunamadı',
                                      style: TextStyle(
                                        color: AppTheme.primaryTextColor,
                                        fontSize: 14,
                                        height: 1.6,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
} 