import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
                    itemCount: allResults.length,
                    itemBuilder: (context, index) {
                      final result = allResults[index];
                      
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              '${result.athleteName[0]}${result.athleteSurname[0]}',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${result.athleteName} ${result.athleteSurname}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.testName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
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
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _showDeleteDialog(result),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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