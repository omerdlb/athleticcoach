import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/services/gemini_service.dart';
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
        'haftalik_program': false,
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
      
      final prompt = '''
Bir sporcu için test sonucu analizi ve antrenman önerisi hazırla.

Sporcu bilgileri:
- Ad: ${athlete?.name ?? result.athleteName} ${athlete?.surname ?? result.athleteSurname}
- Yaş: $age yaş
- Cinsiyet: ${athlete?.gender ?? 'Belirtilmemiş'}
- Branş: ${athlete?.branch ?? 'Belirtilmemiş'}
- Boy: ${athlete?.height ?? 0} cm
- Kilo: ${athlete?.weight ?? 0} kg
- Test: ${result.testName}
- Sonuç: ${result.result} ${result.resultUnit}
- Testin amacı: ${result.testName} testi ile ölçülen kapasite
- Antrenör notu: ${result.notes ?? 'Not girilmemiş'}

Lütfen:
- Sonucu yaş/cinsiyet/branş ortalamalarına göre değerlendir.
- Eksik yönleri ve güçlü yanları belirt.
- Testin amacına göre kapasiteyi geliştirmek için 4 haftalık örnek antrenman planı öner.

Türkçe olarak, detaylı ve uygulanabilir bir şekilde yanıtla. Antrenman planı spesifik ve ölçülebilir olsun.
''';

      final analysis = await GeminiService.generateContent(prompt);
      
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
        );
        
        await database.updateTestResult(updatedResult);
        
        // Widget'taki sonucu da güncelle
        final index = widget.results.indexWhere((r) => r.id == result.id);
        if (index != -1) {
          widget.results[index] = updatedResult;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analiz tamamlandı ve kaydedildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
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
    
    // Bölümleri ayır
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 5) {
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
      sections['haftalik_program'] = _cleanSection(parts[4]);
    } else {
      // Eğer bölümler ayrılamazsa, tüm metni genel notlara koy
      sections['genel_notlar'] = _cleanSection(cleanAnalysis);
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

  Widget _buildAnalysisSection(String resultId, String sectionKey, String title, IconData icon, Color color) {
    final sections = _analysisSections[resultId];
    final content = sections?[sectionKey] ?? 'İçerik bulunamadı';
    final isExpanded = _sectionExpanded[resultId]?[sectionKey] ?? false;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[resultId]![sectionKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                content,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final colorScheme = Theme.of(context).colorScheme;
    
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
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
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
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              '${result.athleteName[0]}${result.athleteSurname[0]}',
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
                                  '${result.athleteName} ${result.athleteSurname}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Saat: ${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
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
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (result.notes?.isNotEmpty == true)
                                Text(
                                  'Not: ${result.notes}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
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
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI analizi yapılıyor...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (hasAnalysis)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Başlık ve toggle butonu
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
                                          color: const Color(0xFF6366F1).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          size: 20,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'AI Analizi',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _isAnalysisExpanded[result.id] == true
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Analiz içeriği (parçalanmış bölümler)
                              if (_isAnalysisExpanded[result.id] == true)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Sonuç Değerlendirmesi
                                      _buildAnalysisSection(
                                        result.id,
                                        'degerlendirme',
                                        'Sonuç Değerlendirmesi',
                                        Icons.analytics,
                                        const Color(0xFF10B981),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Eksik Yönler ve Güçlü Yanlar
                                      _buildAnalysisSection(
                                        result.id,
                                        'eksik_guclu',
                                        'Eksik Yönler ve Güçlü Yanlar',
                                        Icons.trending_up,
                                        const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Genel Notlar
                                      _buildAnalysisSection(
                                        result.id,
                                        'genel_notlar',
                                        'Genel Notlar',
                                        Icons.note,
                                        const Color(0xFF8B5CF6),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Haftalık Program
                                      _buildAnalysisSection(
                                        result.id,
                                        'haftalik_program',
                                        'Haftalık Program',
                                        Icons.calendar_today,
                                        const Color(0xFFEF4444),
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
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Bu Sonucu Analiz Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
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
    final colorScheme = Theme.of(context).colorScheme;
    final hasExistingAnalyses = widget.results.any((r) => r.aiAnalysis != null && r.aiAnalysis!.isNotEmpty);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testName),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.results.length} katılımcı',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDate(widget.results.first.testDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
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
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Tümünü Analiz Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
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