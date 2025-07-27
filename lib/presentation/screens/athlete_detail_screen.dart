import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:athleticcoach/services/gemini_service.dart';

class AthleteDetailScreen extends StatefulWidget {
  final AthleteModel athlete;

  const AthleteDetailScreen({
    super.key,
    required this.athlete,
  });

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  List<TestResultModel> athleteResults = [];
  bool isLoading = true;
  final Map<String, Map<String, String>> _analysisSections = {}; // Parçalanmış analizler
  final Map<String, Map<String, bool>> _sectionExpanded = {}; // Her bölüm için ayrı durum
  final Map<String, bool> _analysisExpanded = {}; // Ana analiz açma/kapama durumu
  final Map<String, bool> _testGroupExpanded = {}; // Test grubu açma/kapama durumu

  @override
  void initState() {
    super.initState();
    _loadAthleteResults();
  }

  Future<void> _loadAthleteResults() async {
    try {
      final results = await AthleteDatabase().getTestResultsByAthlete(widget.athlete.id);
      
      // Her sonuç için analiz durumunu başlat
      for (final result in results) {
        _analysisSections[result.id] = {};
        _sectionExpanded[result.id] = {
          'degerlendirme': false,
          'eksik_guclu': false,
          'genel_notlar': false,
          'haftalik_program': false,
          'beslenme_dinlenme': false,
          'uzun_vadeli': false,
        };
        _analysisExpanded[result.id] = false; // Ana analiz kapalı başlasın
        _testGroupExpanded[result.testName] = true; // Test grupları açık başlasın
        
        // Eğer analiz varsa, parçala
        if (result.aiAnalysis != null && result.aiAnalysis!.isNotEmpty) {
          _analysisSections[result.id] = _parseAnalysis(result.aiAnalysis!);
        }
      }
      
      setState(() {
        athleteResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test sonuçları yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
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
    
    // Bölümleri ayır - yeni detaylı format için
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 7) {
      // Yeni detaylı format: 6 bölüm
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
      sections['haftalik_program'] = _cleanSection(parts[4]);
      sections['beslenme_dinlenme'] = _cleanSection(parts[5]);
      sections['uzun_vadeli'] = _cleanSection(parts[6]);
    } else if (parts.length >= 5) {
      // Eski format: 4 bölüm
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

  Widget _buildGroupedTestResults() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (athleteResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 14),
            Text(
              'Henüz test sonucu yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu sporcu için test oturumu başlatın ve sonuçları burada görüntüleyin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Test sonuçlarını sessionId'ye göre grupla (her test oturumu ayrı)
    final Map<String, List<TestResultModel>> sessionGroups = {};
    for (final result in athleteResults) {
      // Eğer sessionId yoksa, testName + tarih + id kombinasyonu kullan
      final sessionKey = result.sessionId ?? '${result.testName}_${result.testDate.millisecondsSinceEpoch}_${result.id}';
      if (!sessionGroups.containsKey(sessionKey)) {
        sessionGroups[sessionKey] = [];
      }
      sessionGroups[sessionKey]!.add(result);
    }

    // Session gruplarını tarihe göre sırala (yeniden eskiye)
    final sortedSessions = sessionGroups.entries.toList()
      ..sort((a, b) {
        final dateA = a.value.first.testDate;
        final dateB = b.value.first.testDate;
        return dateB.compareTo(dateA);
      });

    // Expand/collapse state'i tut
    for (final session in sortedSessions) {
      if (!_testGroupExpanded.containsKey(session.key)) {
        _testGroupExpanded[session.key] = true;
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedSessions.length,
      itemBuilder: (context, index) {
        final sessionEntry = sortedSessions[index];
        final sessionKey = sessionEntry.key;
        final results = sessionEntry.value;
        final isExpanded = _testGroupExpanded[sessionKey] ?? true;
        
        // İlk sonucun bilgilerini al
        final firstResult = results.first;
        
        // Oturum başlığı için test adı ve tarih
        final sessionTitle = '${firstResult.testName} - Oturum ${index + 1}';
        final sessionDate = '${firstResult.testDate.day.toString().padLeft(2, '0')}.${firstResult.testDate.month.toString().padLeft(2, '0')}.${firstResult.testDate.year} ${firstResult.testDate.hour.toString().padLeft(2, '0')}:${firstResult.testDate.minute.toString().padLeft(2, '0')}';

        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test oturumu başlığı (expand/collapse)
              InkWell(
                onTap: () {
                  setState(() {
                    _testGroupExpanded[sessionKey] = !(isExpanded);
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessionTitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sessionDate,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${results.length} sonuç',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
              // Test sonuçları listesi (expand/collapse)
              if (isExpanded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 2),
                  itemBuilder: (context, resultIndex) {
                    final result = results[resultIndex];
                    final hasAnalysis = result.aiAnalysis != null && result.aiAnalysis!.isNotEmpty;
                    // Dönüşümlü arka plan renkleri
                    final List<Color> bgColors = [
                      AppTheme.primaryColor.withOpacity(0.05), // Açık mor
                      AppTheme.cardBackgroundColor,
                      AppTheme.secondaryColor.withOpacity(0.05), // Açık sarı
                      AppTheme.cardBackgroundColor,
                      AppTheme.accentColor.withOpacity(0.05), // Açık mavi
                      AppTheme.cardBackgroundColor,
                    ];
                    final bgColor = bgColors[resultIndex % bgColors.length];
                    return Dismissible(
                      key: ValueKey(result.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        color: AppTheme.errorColor.withOpacity(0.85),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline, color: AppTheme.whiteTextColor, size: 28),
                            const SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: AppTheme.whiteTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Test Sonucunu Sil', style: TextStyle(color: AppTheme.primaryTextColor)),
                            content: Text('Bu test sonucunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: TextStyle(color: AppTheme.primaryTextColor)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Vazgeç', style: TextStyle(color: AppTheme.primaryColor)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                              ),
                            ],
                          ),
                        );
                        return confirm == true;
                      },
                      onDismissed: (direction) async {
                        await AthleteDatabase().deleteTestResult(result.id);
                        setState(() {
                          athleteResults.removeWhere((r) => r.id == result.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Test sonucu silindi.'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColorWithOpacity,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: AppTheme.secondaryTextColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(result.testDate),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.secondaryTextColor,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.access_time, size: 14, color: AppTheme.secondaryTextColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}:${result.testDate.second.toString().padLeft(2, '0')}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.secondaryTextColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (result.notes?.isNotEmpty == true) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Not: ${result.notes}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.secondaryTextColor,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (hasAnalysis)
                                  InkWell(
                                    onTap: () => _showAnalysis(result),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.13),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI Analizi',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondaryTextColor),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.auto_awesome, color: AppTheme.whiteTextColor),
                                    label: Text('Analiz Et', style: TextStyle(color: AppTheme.whiteTextColor)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: AppTheme.whiteTextColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _showAnalysis(result),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAnalysis(TestResultModel result) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestResultAnalysisScreen(
          athlete: widget.athlete,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(widget.athlete.birthDate);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.athlete.name} ${widget.athlete.surname}'),
         backgroundColor: AppTheme.primaryColor,
         foregroundColor: AppTheme.whiteTextColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.whiteTextColor),
            onPressed: _loadAthleteResults,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: AppTheme.gradientDecoration,
          ),
          SingleChildScrollView(
            padding: AppTheme.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sporcu bilgileri kartı
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8), AppTheme.cardBackgroundColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColorWithOpacity,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.cardBackgroundColor,
                          child: Icon(
                            widget.athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                            size: 32,
                            color: widget.athlete.gender == 'Kadın' ? AppTheme.femaleColor : AppTheme.maleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.athlete.name} ${widget.athlete.surname}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.athlete.branch,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 10),
                        // Detay bilgi kutuları
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _infoBox(Icons.cake, 'Yaş', '$age', mini: true)),
                            const SizedBox(width: 6),
                            Expanded(child: _infoBox(Icons.height, 'Boy', '${widget.athlete.height.toStringAsFixed(0)} cm', mini: true)),
                            const SizedBox(width: 6),
                            Expanded(child: _infoBox(Icons.monitor_weight, 'Kilo', '${widget.athlete.weight.toStringAsFixed(1)} kg', mini: true)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              child: _infoBox(Icons.sports, 'Branş', widget.athlete.branch, mini: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Test Sonuçları başlığı
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Test Sonuçları',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
                // Test Sonuçları
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundWithOpacity,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColorWithOpacity,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  child: _buildGroupedTestResults(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, {bool mini = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: EdgeInsets.symmetric(
        vertical: mini ? 6 : 10,
        horizontal: mini ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColorWithOpacity,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: mini ? 16 : 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: mini ? 10 : 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: mini ? 12 : 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor),
          ),
        ],
      ),
    );
  }
} 

class TestResultAnalysisScreen extends StatefulWidget {
  final AthleteModel athlete;
  final TestResultModel result;
  const TestResultAnalysisScreen({super.key, required this.athlete, required this.result});

  @override
  State<TestResultAnalysisScreen> createState() => _TestResultAnalysisScreenState();
}

class _TestResultAnalysisScreenState extends State<TestResultAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final analysis = widget.result.aiAnalysis;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analiz & Öneri'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: AppTheme.gradientDecoration,
          ),
          Padding(
            padding: AppTheme.getResponsivePadding(context),
            child: analysis == null || analysis.trim().isEmpty
                ? Center(child: Text('Bu test için AI analizi bulunamadı.', style: TextStyle(color: AppTheme.primaryTextColor)))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Analiz & Kişisel Antrenman Planı',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        
                        // Test ve sporcu bilgileri
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      widget.result.testName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: AppTheme.secondaryTextColor),
                                    const SizedBox(width: 6),
                                    Text('Tarih: ${widget.result.testDate.day.toString().padLeft(2, '0')}.${widget.result.testDate.month.toString().padLeft(2, '0')}.${widget.result.testDate.year}', style: TextStyle(color: AppTheme.primaryTextColor)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.analytics, size: 18, color: AppTheme.secondaryTextColor),
                                    const SizedBox(width: 6),
                                    Text('Sonuç: ${widget.result.result} ${widget.result.resultUnit}', style: TextStyle(color: AppTheme.primaryTextColor)),
                                  ],
                                ),
                                if (widget.result.notes?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.note, size: 18, color: AppTheme.secondaryTextColor),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('Not: ${widget.result.notes}', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.primaryTextColor))),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 22),
                        
                        // AI Analizi - Tek Kart
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      'AI Performans Analizi',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Tam analiz metni
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
                                  child: Text(
                                    analysis,
                                    style: TextStyle(
                                      color: AppTheme.primaryTextColor,
                                      fontSize: 15,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 