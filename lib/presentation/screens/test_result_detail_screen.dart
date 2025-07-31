import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_result_analysis_screen.dart';
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:athleticcoach/services/pdf_export_service.dart';
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
  List<TestResultModel> _currentResults = []; // Güncel sonuçlar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpdatedResults();
  }

  Future<void> _loadUpdatedResults() async {
    try {
      // Veritabanından güncel test sonuçlarını çek
      final database = AthleteDatabase();
      final allResults = await database.getAllTestResults();
      
      // Aynı test oturumundaki sonuçları filtrele
      if (widget.results.isEmpty) {
        setState(() {
          _currentResults = [];
          _isLoading = false;
        });
        return;
      }
      
      final sessionId = widget.results.first.sessionId;
      final updatedResults = allResults.where((r) => r.sessionId == sessionId).toList();
      
      // Her sonuç için analiz durumunu başlat
      for (final result in updatedResults) {
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
      
      setState(() {
        _currentResults = updatedResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Güncel sonuçlar yüklenirken hata: $e');
      setState(() {
        _currentResults = widget.results;
        _isLoading = false;
      });
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
        final index = _currentResults.indexWhere((r) => r.id == result.id);
        if (index != -1) {
          setState(() {
            _currentResults[index] = updatedResult;
          });
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
    
    for (final result in _currentResults) {
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
    // Türkçe tarih formatı: DD.MM.YYYY
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _exportToPdf(TestResultModel result) async {
    try {
      await PdfExportService.exportTestAnalysis(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF başarıyla oluşturuldu'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }



  DateTime _parseDate(String dateString) {
    final parts = dateString.split('.');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    }
    // Eğer format farklıysa, varsayılan olarak bugünün tarihini döndür
    return DateTime.now();
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



  Widget _buildResultsList() {
    // Boş liste kontrolü
    if (_currentResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz test sonucu yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    // Test sonuçlarını tarihe göre grupla
    final Map<String, List<TestResultModel>> dateGroups = {};
    for (final result in _currentResults) {
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sporcu bilgisi ve sonuç - yeni tasarım
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                '${(result.athleteName?.isNotEmpty == true ? result.athleteName![0] : "?")}${(result.athleteSurname?.isNotEmpty == true ? result.athleteSurname![0] : "")}',
                                style: TextStyle(
                                  color: AppTheme.whiteTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Sporcu bilgileri
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${result.athleteName ?? "Bilinmeyen"} ${result.athleteSurname ?? ""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Test sonucu - ayrı bölüm
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.accentColor.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Sonucu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.analytics,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Notlar - varsa göster
                      if (result.notes?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_alt,
                                    size: 16,
                                    color: AppTheme.secondaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Notlar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                result.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Analiz bölümü
                      if (isAnalyzing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
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
                          margin: const EdgeInsets.only(top: 16),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            children: [
                              // Başlık - Tıklanabilir
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isAnalysisExpanded[result.id] = !(_isAnalysisExpanded[result.id] ?? false);
                                  });
                                },
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          (_isAnalysisExpanded[result.id] ?? false) 
                                              ? Icons.keyboard_arrow_up 
                                              : Icons.keyboard_arrow_down,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // AI Analizi İçeriği - Daraltılabilir
                              if (_isAnalysisExpanded[result.id] ?? false)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Tam analiz metni
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          result.aiAnalysis!,
                                          style: TextStyle(
                                            color: AppTheme.primaryTextColor,
                                            fontSize: 14,
                                            height: 1.6,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Butonlar
                                      Row(
                                        children: [
                                          // Detayları Gör Butonu
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => TestResultAnalysisScreen(
                                                      testResult: result,
                                                    ),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_forward,
                                                      color: AppTheme.primaryColor,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Detayları Gör',
                                                        style: TextStyle(
                                                          color: AppTheme.primaryColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 8),
                                          
                                          // PDF Export Butonu
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _exportToPdf(result),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.picture_as_pdf,
                                                      color: AppTheme.secondaryColor,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'PDF İndir',
                                                        style: TextStyle(
                                                          color: AppTheme.secondaryColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
    final hasExistingAnalyses = _currentResults.any((r) => r.aiAnalysis != null && r.aiAnalysis!.isNotEmpty);
    
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
                        color: AppTheme.whiteTextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentResults.length} katılımcı',
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
                        color: AppTheme.whiteTextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentResults.isNotEmpty ? _formatDate(_currentResults.first.testDate) : _formatDate(DateTime.now()),
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }
}