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
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTestNames.length,
      itemBuilder: (context, index) {
        final testName = sortedTestNames[index];
        final results = testGroups[testName]!;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // Test başlığı (daraltılabilir)
              InkWell(
                onTap: () {
                  setState(() {
                    _testGroupExpanded[testName] = !(_testGroupExpanded[testName] ?? true);
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${results.length} test sonucu',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        (_testGroupExpanded[testName] ?? true)
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Test sonuçları listesi (daraltılabilir)
              if (_testGroupExpanded[testName] ?? true)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, resultIndex) {
                                     final result = results[resultIndex];
                   final hasAnalysis = result.aiAnalysis != null && result.aiAnalysis!.isNotEmpty;
                   final isAnalysisExpanded = _analysisExpanded[result.id] ?? false;
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: resultIndex < results.length - 1
                            ? BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sonuç bilgileri
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: colorScheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(result.testDate),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: colorScheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${result.testDate.hour.toString().padLeft(2, '0')}:${result.testDate.minute.toString().padLeft(2, '0')}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
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
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Analiz bölümü
                          if (hasAnalysis)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
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
                                         _analysisExpanded[result.id] = !isAnalysisExpanded;
                                       });
                                     },
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              size: 16,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'AI Analizi',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isAnalysisExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: const Color(0xFF6B7280),
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Analiz içeriği (parçalanmış bölümler)
                                  if (isAnalysisExpanded)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
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
                                          const SizedBox(height: 8),
                                          
                                          // Eksik Yönler ve Güçlü Yanlar
                                          _buildAnalysisSection(
                                            result.id,
                                            'eksik_guclu',
                                            'Eksik Yönler ve Güçlü Yanlar',
                                            Icons.trending_up,
                                            const Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Genel Notlar
                                          _buildAnalysisSection(
                                            result.id,
                                            'genel_notlar',
                                            'Genel Notlar',
                                            Icons.note,
                                            const Color(0xFF8B5CF6),
                                          ),
                                          const SizedBox(height: 8),
                                          
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
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Analiz Et'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _showAnalysis(result),
                              ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sporcu bilgileri kartı
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        widget.athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                        size: 50,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.athlete.name} ${widget.athlete.surname}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.athlete.branch,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Detay bilgileri
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.cake,
                            title: 'Yaş',
                            value: '$age yaş',
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.monitor_weight,
                            title: 'Kilo',
                            value: '${widget.athlete.weight} kg',
                            color: colorScheme.secondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.height,
                            title: 'Boy',
                            value: '${widget.athlete.height} cm',
                            color: colorScheme.tertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.person,
                            title: 'Cinsiyet',
                            value: widget.athlete.gender,
                            color: colorScheme.surfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test sonuçları bölümü
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Sonuçları',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (athleteResults.isEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz test sonucu yok',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu sporcu için test oturumu başlatın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildGroupedTestResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[700], size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
  String? analysis;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() { loading = true; error = null; });
    final prompt = '''Bir sporcu için test sonucu analizi ve antrenman önerisi hazırla.\nSporcu bilgileri:\n- Ad: ${widget.athlete.name} ${widget.athlete.surname}\n- Yaş: ${DateTime.now().year - widget.athlete.birthDate.year}\n- Cinsiyet: ${widget.athlete.gender}\n- Branş: ${widget.athlete.branch}\n- Test: ${widget.result.testName}\n- Sonuç: ${widget.result.result} ${widget.result.resultUnit}\n- Testin amacı: ${widget.result.testName} testi ile ölçülen kapasiteyi geliştirmek\n\nLütfen:\n- Sonucu yaş/cinsiyet/branş ortalamalarına göre değerlendir.\n- Eksik yönleri ve güçlü yanları belirt.\n- Testin hedeflediği kapasiteyi geliştirmek için 4 haftalık örnek antrenman planı öner.''';
    try {
      final response = await GeminiService.generateContent(prompt);
      setState(() {
        analysis = response;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analiz & Öneri'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Hata: $error'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Analiz & Kişisel Antrenman Planı',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          analysis ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
} 