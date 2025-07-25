import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
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
          SnackBar(content: Text('Test sonuçları yüklenirken hata: $e')),
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

  Widget _buildGroupedTestResults() {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (athleteResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Henüz test sonucu yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu sporcu için test oturumu başlatın ve sonuçları burada görüntüleyin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    // Test sonuçlarını test adına göre grupla
    final Map<String, List<TestResultModel>> testGroups = {};
    for (final result in athleteResults) {
      if (!testGroups.containsKey(result.testName)) {
        testGroups[result.testName] = [];
      }
      testGroups[result.testName]!.add(result);
    }
    // Her test grubundaki sonuçları tarihe göre sırala (yeniden eskiye)
    for (final group in testGroups.values) {
      group.sort((a, b) => b.testDate.compareTo(a.testDate));
    }
    // Test gruplarını alfabetik sırala
    final sortedTestNames = testGroups.keys.toList()..sort();
    // Expand/collapse state'i tut
    _testGroupExpanded.addEntries(sortedTestNames.where((k) => !_testGroupExpanded.containsKey(k)).map((k) => MapEntry(k, true)));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTestNames.length,
      itemBuilder: (context, index) {
        final testName = sortedTestNames[index];
        final results = testGroups[testName]!;
        final isExpanded = _testGroupExpanded[testName] ?? true;
        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test başlığı (expand/collapse)
              InkWell(
                onTap: () {
                  setState(() {
                    _testGroupExpanded[testName] = !(isExpanded);
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, color: colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          testName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                      ),
                      Text(
                        '${results.length} test',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: colorScheme.primary,
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
                      const Color(0xFFE0E7FF), // Açık mor
                      Colors.white,
                      const Color(0xFFFFF7E0), // Açık sarı
                      Colors.white,
                      const Color(0xFFE0F7FA), // Açık mavi
                      Colors.white,
                    ];
                    final bgColor = bgColors[resultIndex % bgColors.length];
                    return Dismissible(
                      key: ValueKey(result.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.redAccent.withOpacity(0.85),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Test Sonucunu Sil'),
                            content: const Text('Bu test sonucunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Vazgeç'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
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
                          const SnackBar(content: Text('Test sonucu silindi.')),
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
                              color: colorScheme.primary.withOpacity(0.06),
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
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: colorScheme.outline),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(result.testDate),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (result.notes?.isNotEmpty == true) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Not: ${result.notes}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.outline,
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
                                        color: colorScheme.primary.withOpacity(0.13),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI Analizi',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF6B7280)),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.auto_awesome),
                                    label: const Text('Analiz Et'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final age = _calculateAge(widget.athlete.birthDate);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.athlete.name} ${widget.athlete.surname}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAthleteResults,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5FE), Color(0xFFFDF6E3)],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sporcu bilgileri kartı
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.10),
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
                          backgroundColor: Colors.white,
                          child: Icon(
                            widget.athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.athlete.name} ${widget.athlete.surname}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.athlete.branch,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
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
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                // Test Sonuçları
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.07),
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
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: mini ? 16 : 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: mini ? 10 : 12, color: const Color(0xFF6366F1), fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: mini ? 12 : 15, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final analysis = widget.result.aiAnalysis;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analiz & Öneri'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5FE), Color(0xFFFDF6E3)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: analysis == null || analysis.trim().isEmpty
                ? Center(child: Text('Bu test için AI analizi bulunamadı.'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Analiz & Kişisel Antrenman Planı',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
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
                                    Icon(Icons.fitness_center, color: colorScheme.primary, size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      widget.result.testName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text('Tarih: ${widget.result.testDate.day.toString().padLeft(2, '0')}.${widget.result.testDate.month.toString().padLeft(2, '0')}.${widget.result.testDate.year}'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.analytics, size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text('Sonuç: ${widget.result.result} ${widget.result.resultUnit}'),
                                  ],
                                ),
                                if (widget.result.notes?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.note, size: 18, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('Not: ${widget.result.notes}', style: const TextStyle(fontStyle: FontStyle.italic))),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Analiz metnini bölümlere ayır ve şık kartlar halinde göster
                        ..._buildAnalysisCards(analysis, context),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnalysisCards(String analysis, BuildContext context) {
    // Bölümleri başlıklara göre ayır (ör: 1. Sonuç Değerlendirmesi, 2. Eksik Yönler ...)
    final RegExp sectionExp = RegExp(r'(\d+\.\s+)([\s\S]*?)(?=(\d+\.\s+|\$))');
    final matches = sectionExp.allMatches(analysis);
    final List<Widget> cards = [];
    final List<IconData> icons = [
      Icons.insights, // 1. Sonuç Değerlendirmesi
      Icons.trending_up, // 2. Eksik Yönler ve Güçlü Yanlar
      Icons.note_alt, // 3. Genel Notlar
      Icons.calendar_month, // 4. Haftalık Program
    ];
    final List<Color> colors = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
    ];
    int i = 0;
    for (final match in matches) {
      final section = match.group(0)?.trim() ?? '';
      if (section.isEmpty) continue;
      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors[i % colors.length].withOpacity(0.10), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors[i % colors.length].withOpacity(0.13),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors[i % colors.length].withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icons[i % icons.length], color: colors[i % colors.length], size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      i++;
    }
    // Eğer hiç bölüm bulunamazsa tüm metni tek kartta göster
    if (cards.isEmpty && analysis.trim().isNotEmpty) {
      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.13),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Text(
              analysis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
        ),
      );
    }
    return cards;
  }
} 