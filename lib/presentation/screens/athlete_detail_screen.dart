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

  @override
  void initState() {
    super.initState();
    _loadAthleteResults();
  }

  Future<void> _loadAthleteResults() async {
    try {
      final results = await AthleteDatabase().getTestResultsByAthlete(widget.athlete.id);
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: athleteResults.length,
                itemBuilder: (context, index) {
                  final result = athleteResults[index];
                  
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        child: Icon(
                          Icons.fitness_center,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        result.testName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
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
                            ],
                          ),
                          if (result.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Not: ${result.notes}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
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
                      trailing: Container(
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
                    ),
                  );
                },
              ),
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