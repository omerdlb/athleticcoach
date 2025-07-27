import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/presentation/screens/test_result_detail_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';
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
      print('=== TEST SONUÇLARI YÜKLENİYOR ===');
      final results = await AthleteDatabase().getAllTestResults();
      print('Toplam ${results.length} test sonucu yüklendi');
      
      // Her sonucun tarih bilgisini kontrol et
      for (final result in results) {
        print('Test: ${result.testName} | Sporcu: ${result.athleteName} | Tarih: ${result.testDate}');
      }
      print('==================================');
      
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
          SnackBar(
            content: Text('Test sonuçları yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
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
          SnackBar(
            content: Text('Test sonucu silindi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
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
    // Test sonuçlarını sessionId'ye göre grupla
    final Map<String, List<TestResultModel>> testSessions = {};
    for (final result in allResults) {
      final sessionKey = result.sessionId;
      if (!testSessions.containsKey(sessionKey)) {
        testSessions[sessionKey] = [];
      }
      testSessions[sessionKey]!.add(result);
    }
    // Test oturumlarını tarihe göre sırala (en yeni en üstte)
    final sortedTestSessions = testSessions.entries.toList()
      ..sort((a, b) => b.value.first.testDate.compareTo(a.value.first.testDate));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonuçları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.whiteTextColor),
            onPressed: _loadResults,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : allResults.isEmpty
              ? Center(
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
                      const SizedBox(height: 8),
                      Text(
                        'Yeni test oturumu başlatın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
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
                                    currentDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppTheme.getResponsiveFontSize(context, 18),
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          
                          // Test oturumu kartı
                          GestureDetector(
                            onLongPress: () => _showActionSheet(context, results),
                            child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                              onTap: () => _showResultDetail(firstResult),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Test adı ve ikon
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppTheme.primaryColor,
                                            radius: 20,
                                child: Icon(
                                  Icons.analytics,
                                              color: AppTheme.whiteTextColor,
                                              size: 20,
                                ),
                              ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${firstResult.testName} (Oturum ${index + 1})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                                    fontSize: AppTheme.getResponsiveFontSize(context, 18),
                                                    color: AppTheme.primaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                                      Icons.people,
                                        size: 16,
                                                      color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                                      '${results.length} katılımcı',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: AppTheme.getResponsiveFontSize(context, 14),
                                                        color: AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.secondaryColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: AppTheme.secondaryColor.withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Oturum ${index + 1}',
                                                        style: TextStyle(
                                                          fontSize: AppTheme.getResponsiveFontSize(context, 12),
                                                          color: AppTheme.secondaryColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                                          ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                            color: AppTheme.secondaryTextColor,
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Tarih ve saat bilgisi
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: AppTheme.secondaryTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(firstResult.testDate),
                                            style: TextStyle(
                                              fontSize: AppTheme.getResponsiveFontSize(context, 14),
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: AppTheme.secondaryTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${firstResult.testDate.hour.toString().padLeft(2, '0')}:${firstResult.testDate.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: AppTheme.getResponsiveFontSize(context, 14),
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                  ),
                                ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Katılımcı listesi
                                      if (results.length <= 3) ...[
                                        Text(
                                          'Katılımcılar:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppTheme.getResponsiveFontSize(context, 14),
                                            color: AppTheme.primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: results.map((result) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                '${result.athleteName} ${result.athleteSurname}',
                                                style: TextStyle(
                                                  fontSize: AppTheme.getResponsiveFontSize(context, 12),
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Katılımcılar:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppTheme.getResponsiveFontSize(context, 14),
                                            color: AppTheme.primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            ...results.take(3).map((result) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${result.athleteName} ${result.athleteSurname}',
                                                  style: TextStyle(
                                                    fontSize: AppTheme.getResponsiveFontSize(context, 12),
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppTheme.secondaryColor.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                '+${results.length - 3} daha',
                                                style: TextStyle(
                                                  fontSize: AppTheme.getResponsiveFontSize(context, 12),
                                                  color: AppTheme.secondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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
    // Aynı test oturumundaki tüm sonuçları bul (session key'e göre)
    final sessionKey = result.sessionId;
    final sameTestResults = allResults.where((r) => r.sessionId == sessionKey).toList();
    
    // Recent test'e ekle
    _addToRecentTests(result);
    
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

  Future<void> _addToRecentTests(TestResultModel result) async {
    try {
      final recentTest = RecentTestModel(
        testName: result.testName,
        athleteName: '', // Sporcu ismi artık kullanılmıyor
        testDate: _formatDate(result.testDate),
        viewedAt: DateTime.now(),
      );
      
      await AthleteDatabase().addRecentTest(recentTest);
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Recent test eklenirken hata: $e');
    }
  }

  void _showDeleteDialog(TestResultModel result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Sonucunu Sil', style: TextStyle(color: AppTheme.primaryTextColor)),
        content: Text(
          '${result.athleteName} ${result.athleteSurname} için ${result.testName} sonucunu silmek istediğinizden emin misiniz?',
          style: TextStyle(color: AppTheme.primaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteResult(result);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, List<TestResultModel> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Test Oturumu İşlemleri',
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
                size: 24,
              ),
              title: Text(
                'Test Oturumunu Sil',
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
              subtitle: Text(
                '${results.length} katılımcının sonuçları silinecek',
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(context, 14),
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteSessionDialog(results);
              },
            ),
            
            ListTile(
              leading: Icon(
                Icons.file_download_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              title: Text(
                'Dışarı Aktar (PDF)',
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              subtitle: Text(
                'Test sonuçlarını PDF olarak kaydet',
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(context, 14),
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: PDF export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF dışarı aktarma özelliği yakında eklenecek'),
                    backgroundColor: AppTheme.warningColor,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.secondaryTextColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteSessionDialog(List<TestResultModel> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Test Oturumunu Sil',
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu test oturumunu silmek istediğinizden emin misiniz?',
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Silinecek veriler:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${results.first.testName}',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${results.length} katılımcının sonuçları',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${_formatDate(results.first.testDate)} ${results.first.testDate.hour.toString().padLeft(2, '0')}:${results.first.testDate.minute.toString().padLeft(2, '0')}:${results.first.testDate.second.toString().padLeft(2, '0')}.${results.first.testDate.millisecond.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTestSession(results);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.whiteTextColor,
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTestSession(List<TestResultModel> results) async {
    try {
      // Tüm test sonuçlarını sil
      for (final result in results) {
        await AthleteDatabase().deleteTestResult(result.id);
      }
      
      // Listeyi yenile
      await _loadResults();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test oturumu başarıyla silindi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
} 