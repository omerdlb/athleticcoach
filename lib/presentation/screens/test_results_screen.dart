import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_result_detail_screen.dart';
import 'package:flutter/material.dart';

class TestResultsScreen extends StatefulWidget {
  const TestResultsScreen({super.key});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  List<TestResultModel> allResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final results = await AthleteDatabase().getAllTestResults();
      setState(() {
        allResults = results;
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

  Future<void> _deleteResult(TestResultModel result) async {
    try {
      await AthleteDatabase().deleteTestResult(result.id);
      await _loadResults(); // Listeyi yenile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test sonucu silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('.');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Test sonuçlarını test oturumlarına göre grupla
    final Map<String, List<TestResultModel>> testSessions = {};
    for (final result in allResults) {
      if (!testSessions.containsKey(result.testId)) {
        testSessions[result.testId] = [];
      }
      testSessions[result.testId]!.add(result);
    }
    
    // Test oturumlarını tarihe göre grupla ve sırala
    final Map<String, List<MapEntry<String, List<TestResultModel>>>> dateGroups = {};
    
    for (final entry in testSessions.entries) {
      final firstResult = entry.value.first;
      final dateKey = _formatDate(firstResult.testDate);
      
      if (!dateGroups.containsKey(dateKey)) {
        dateGroups[dateKey] = [];
      }
      dateGroups[dateKey]!.add(entry);
    }
    
    // Tarihleri yeniden eskiye sırala
    final sortedDates = dateGroups.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDate(a);
        final dateB = _parseDate(b);
        return dateB.compareTo(dateA); // Yeniden eskiye
      });
    
    final sortedTestSessions = <MapEntry<String, List<TestResultModel>>>[];
    for (final date in sortedDates) {
      // Her tarih grubundaki test oturumlarını da tarihe göre sırala
      final sessionsForDate = dateGroups[date]!;
      sessionsForDate.sort((a, b) {
        final dateA = a.value.first.testDate;
        final dateB = b.value.first.testDate;
        return dateB.compareTo(dateA); // Yeniden eskiye
      });
      sortedTestSessions.addAll(sessionsForDate);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonuçları'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz test sonucu yok',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yeni test oturumu başlatın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadResults,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedTestSessions.length,
                    itemBuilder: (context, index) {
                      final testSession = sortedTestSessions[index];
                      final results = testSession.value;
                      final firstResult = results.first;
                      final currentDate = _formatDate(firstResult.testDate);
                      
                      // Önceki test oturumunun tarihini kontrol et
                      final previousDate = index > 0 
                          ? _formatDate(sortedTestSessions[index - 1].value.first.testDate)
                          : null;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tarih başlığı (sadece farklı tarihlerde göster)
                          if (previousDate != currentDate) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 8),
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
                                    currentDate,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          
                          // Test oturumu kartı
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _showResultDetail(firstResult),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primary,
                                child: Icon(
                                  Icons.analytics,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              title: Text(
                                firstResult.testName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${results.length} katılımcı',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 16,
                                        color: colorScheme.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(firstResult.testDate),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  void _showResultDetail(TestResultModel result) {
    // Aynı test oturumundaki tüm sonuçları bul (testId'ye göre)
    final sameTestResults = allResults.where((r) => 
      r.testId == result.testId
    ).toList();
    
    // Detay sayfasına git
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestResultDetailScreen(
          testName: result.testName,
          testId: result.testId,
          results: sameTestResults,
        ),
      ),
    );
  }

  void _showDeleteDialog(TestResultModel result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Sonucunu Sil'),
        content: Text(
          '${result.athleteName} ${result.athleteSurname} için ${result.testName} sonucunu silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteResult(result);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
} 