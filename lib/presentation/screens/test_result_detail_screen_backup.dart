import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_result_analysis_screen.dart';
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class TestResultDetailScreen extends StatefulWidget {
  final String testName;
  final String testId;
  final List<TestResultModel> results;

  const TestResultDetailScreen({
    super.key,
    required this.testName,
    required this.testId,
    required this.results,
  });

  @override
  State<TestResultDetailScreen> createState() => _TestResultDetailScreenState();
}

class _TestResultDetailScreenState extends State<TestResultDetailScreen> {
  final Map<String, bool> _isAnalyzing = {};
  final Map<String, bool> _isAnalysisExpanded = {};
  final Map<String, Map<String, String>> _analysisSections = {}; // Parçalanmış analizler
  final Map<String, Map<String, bool>> _sectionExpanded = {}; // Her bölüm için ayrı durum

  @override
  void initState() {
    super.initState();
    // Her sonuç için analiz durumunu başlat
    for (final result in widget.results) {
      _isAnalyzing[result.id] = false;
      _isAnalysisExpanded[result.id] = false;
      _analysisSections[result.id] = {};
      _sectionExpanded[result.id] = {
        'degerlendirme': false,
        'eksik_guclu': false,
        'genel_notlar': false,
      };
      
      // Eğer analiz varsa, parçala
      if (result.aiAnalysis != null && result.aiAnalysis!.isNotEmpty) {
        _analysisSections[result.id] = _parseAnalysis(result.aiAnalysis!);
      }
    }
  }

  Future<void> _analyzeResult(TestResultModel result) async {
    setState(() {
      _isAnalyzing[result.id] = true;
    });

    try {
      // Sporcu bilgilerini veritabanından çek
      final database = AthleteDatabase();
      final athletes = await database.getAllAthletes();
      
      AthleteModel? athlete;
      try {
        athlete = athletes.firstWhere((a) => a.id == result.athleteId);
      } catch (e) {
        // Sporcu bulunamadıysa, sadece mevcut bilgileri kullan
        debugPrint('Sporcu veritabanında bulunamadı: ${result.athleteId}');
      }
      
      final age = athlete != null 
          ? DateTime.now().year - athlete.birthDate.year 
          : DateTime.now().year - result.testDate.year;
      
      final analysis = await GeminiService.generateDetailedAnalysis(
        athleteName: athlete?.name ?? result.athleteName,
        athleteSurname: athlete?.surname ?? result.athleteSurname,
        age: age,
        gender: athlete?.gender ?? 'Belirtilmemiş',
        branch: athlete?.branch ?? 'Belirtilmemiş',
        height: athlete?.height ?? 0,
        weight: athlete?.weight ?? 0,
        testName: result.testName,
        result: result.result,
        resultUnit: result.resultUnit,
        notes: result.notes,
      );
      
      if (mounted && analysis != null) {
        // Analizi parçala
        setState(() {
          _analysisSections[result.id] = _parseAnalysis(analysis);
        });
        
        // Analizi hemen veritabanına kaydet
        final database = AthleteDatabase();
        
        final updatedResult = TestResultModel(
          id: result.id,
          testId: result.testId,
          testName: result.testName,
          athleteId: result.athleteId,
          athleteName: result.athleteName,
          athleteSurname: result.athleteSurname,
          testDate: result.testDate,
          result: result.result,
          resultUnit: result.resultUnit,
          notes: result.notes,
          aiAnalysis: analysis,
          sessionId: result.sessionId,
        );
        
        await database.updateTestResult(updatedResult);
        
        // Widget'taki sonucu da güncelle
        final index = widget.results.indexWhere((r) => r.id == result.id);
        if (index != -1) {
          widget.results[index] = updatedResult;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz tamamlandı ve kaydedildi!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing[result.id] = false;
        });
      }
    }
  }

  Future<void> _analyzeAllResults() async {
    int analyzedCount = 0;
    
    for (final result in widget.results) {
      if (result.aiAnalysis == null || result.aiAnalysis!.isEmpty) {
        await _analyzeResult(result);
        analyzedCount++;
        // Her analiz arasında kısa bir bekleme
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    if (analyzedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$analyzedCount sonuç analiz edildi ve kaydedildi!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  Map<String, String> _parseAnalysis(String analysis) {
    final sections = <String, String>{};
    
    // Gereksiz çizgileri ve formatlamaları temizle
    String cleanAnalysis = analysis
        .replaceAll(RegExp(r'-{3,}'), '') // Üç veya daha fazla tire
        .replaceAll(RegExp(r'={3,}'), '') // Üç veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{3,}'), '') // Üç veya daha fazla yıldız
        .replaceAll(RegExp(r'_{3,}'), '') // Üç veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
    
    // Bölümleri ayır - yeni 3 bölümlü format için
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 4) { // 3 bölüm için (0. boş, 1-2-3. bölümler)
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
    } else {
      // Fallback: Tüm analizi tek bölüm olarak göster
      sections['degerlendirme'] = cleanAnalysis;
      sections['eksik_guclu'] = 'Bölüm ayrıştırılamadı';
      sections['genel_notlar'] = 'Bölüm ayrıştırılamadı';
    }
    
    return sections;
  }

  String _cleanSection(String section) {
    return section
        .replaceAll(RegExp(r'-{2,}'), '') // İki veya daha fazla tire
        .replaceAll(RegExp(r'={2,}'), '') // İki veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{2,}'), '') // İki veya daha fazla yıldız
        .replaceAll(RegExp(r'_{2,}'), '') // İki veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
  }

  Widget _buildAnalysisSection(String sectionKey, String title, IconData icon, Color color, TestResultModel result) {
    final sections = _analysisSections[result.id];
    final content = sections?[sectionKey] ?? 'İçerik bulunamadı';
    final isExpanded = _sectionExpanded[result.id]?[sectionKey] ?? false;
    
    return Container(
      width: 250, // Yatay kartlar için sabit genişlik
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColorWithOpacity,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[result.id]![sectionKey] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                        fontSize: AppTheme.getResponsiveFontSize(context, 16),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: color,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // İçerik
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                content,
                style: TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    // Test sonuçlarını tarihe göre grupla
    final Map<String, List<TestResultModel>> dateGroups = {};
    for (final result in widget.results) {
      final dateKey = _formatDate(result.testDate);
      if (!dateGroups.containsKey(dateKey)) {
        dateGroups[dateKey] = [];
      }
      dateGroups[dateKey]!.add(result);
    }
    
    // Tarihleri yeniden eskiye sırala
    final sortedDates = dateGroups.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDate(a);
        final dateB = _parseDate(b);
        return dateB.compareTo(dateA); // Yeniden eskiye
      });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final resultsForDate = dateGroups[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih başlığı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bu tarihteki test sonuçları
            ...resultsForDate.map((result) {
              final isAnalyzing = _isAnalyzing[result.id] ?? false;
              final existingAnalysis = result.aiAnalysis;
              final hasAnalysis = existingAnalysis != null && existingAnalysis.isNotEmpty;
              
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
                      // Sporcu bilgisi ve sonuç
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              '${result.athleteName[0]}${result.athleteSurname[0]}',
                              style: TextStyle(
                                color: AppTheme.whiteTextColor,
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
                                  '${result.athleteName} ${result.athleteSurname}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTextColor,
                                  ),
                                ),
                                Text(
                                  'Saat: ${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}:${result.testDate.second.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (result.notes?.isNotEmpty == true)
                                Text(
                                  'Not: ${result.notes}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Analiz bölümü
                      if (isAnalyzing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryColor),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI analizi yapılıyor...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (hasAnalysis)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColorWithOpacity,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Başlık
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.1),
                                      AppTheme.accentColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        size: 22,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Analizi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: AppTheme.getResponsiveFontSize(context, 18),
                                              color: AppTheme.primaryTextColor,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Performans değerlendirmesi',
                                            style: TextStyle(
                                              fontSize: AppTheme.getResponsiveFontSize(context, 13),
                                              color: AppTheme.secondaryTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // AI Analizi İçeriği
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      existingAnalysis!,
                                      style: TextStyle(
                                        color: AppTheme.primaryTextColor,
                                        fontSize: 14,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Detayları Gör Butonu
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => TestResultAnalysisScreen(
                                              testResult: result,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward,
                                              color: AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Detayları Gör',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _analyzeResult(result),
                          icon: Icon(Icons.auto_awesome, color: AppTheme.whiteTextColor),
                          label: Text('Bu Sonucu Analiz Et', style: TextStyle(color: AppTheme.whiteTextColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.whiteTextColor,
                            elevation: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingAnalyses = widget.results.any((r) => r.aiAnalysis != null && r.aiAnalysis!.isNotEmpty);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Test bilgisi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.testName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.whiteTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteTextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.results.length} katılımcı',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.whiteTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteTextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDate(widget.results.first.testDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.whiteTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Analiz butonları
          if (!hasExistingAnalyses)
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _analyzeAllResults,
                icon: Icon(Icons.auto_awesome, color: AppTheme.whiteTextColor),
                label: Text('Tümünü Analiz Et', style: TextStyle(color: AppTheme.whiteTextColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.whiteTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
          
          // Katılımcı listesi
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }
}