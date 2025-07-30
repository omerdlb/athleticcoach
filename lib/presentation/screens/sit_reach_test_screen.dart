import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class SitReachTestScreen extends StatefulWidget {
  const SitReachTestScreen({super.key});

  @override
  State<SitReachTestScreen> createState() => _SitReachTestScreenState();
}

class _SitReachTestScreenState extends State<SitReachTestScreen> {
  final AthleteDatabase _database = AthleteDatabase();
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    try {
      final athletes = await _database.getAllAthletes();
      setState(() {
        _allAthletes = athletes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sporcular yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showMeasurementDialog(AthleteModel athlete) {
    final reachController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.name} ${athlete.surname} - Sit and Reach',
          style: TextStyle(color: AppTheme.primaryTextColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bel ve hamstring esnekliği testi',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Uzanma mesafesi
              TextField(
                controller: reachController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Uzanma Mesafesi (cm)',
                  hintText: 'Örn: 15.5 (pozitif) veya -5.2 (negatif)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              
              // Notlar
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notlar (Opsiyonel)',
                  hintText: 'Test koşulları, gözlemler...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              
              // Performans norm değerleri
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sit and Reach Norm Değerleri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${athlete.gender == "Erkek" ? "Erkek:" : "Kadın:"} '
                      '${athlete.gender == "Erkek" ? "Mükemmel >15cm, İyi 10-15cm, Orta 5-10cm" : "Mükemmel >20cm, İyi 15-20cm, Orta 10-15cm"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal', style: TextStyle(color: AppTheme.secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              final reach = double.tryParse(reachController.text.replaceAll(',', '.'));
              
              if (reach != null) {
                Navigator.of(context).pop();
                _saveResult(athlete, reach, notesController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen geçerli bir mesafe girin'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteTextColor,
            ),
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(double reach, String gender) {
    if (gender == "Erkek") {
      if (reach > 15) return "Mükemmel";
      if (reach >= 10) return "İyi";
      if (reach >= 5) return "Orta";
      return "Zayıf";
    } else {
      if (reach > 20) return "Mükemmel";
      if (reach >= 15) return "İyi";
      if (reach >= 10) return "Orta";
      return "Zayıf";
    }
  }

  Future<void> _saveResult(AthleteModel athlete, double reach, String notes) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final performanceLevel = _getPerformanceLevel(reach, athlete.gender);
      
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: 'sit-reach',
        testName: 'Sit and Reach Test',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testDate: DateTime.now(),
        result: reach,
        resultUnit: 'cm',
        notes: notes.isNotEmpty ? notes : 'Performans Seviyesi: $performanceLevel',
        sessionId: sessionId,
      );

      await _database.insertTestResult(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - ${reach}cm ($performanceLevel)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sit and Reach Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test bilgisi kartı
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.accessibility_new,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sit and Reach Test',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    ),
                                      Text(
                                        'Bel ve Hamstring Esnekliği Testi',
                                        style: TextStyle(
                                          color: AppTheme.secondaryTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Test Protokolü:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Otur-uzan kutusu veya cetvel hazırlanır\n'
                            '2. Ayak tabanları kutuya dayalı şekilde otur\n'
                            '3. Eller üst üste, öne doğru en uzağa uzan\n'
                            '4. Uzanılan mesafe kutu veya cetvel üzerinden okunur\n'
                            '5. 3 deneme yapılır, en iyi sonuç alınır',
                            style: TextStyle(
                              color: AppTheme.primaryTextColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.rule, size: 16, color: AppTheme.secondaryColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Önemli: Dizler düz + Ayak tabanları kutuya dayalı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Kullanım alanları
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sports_gymnastics, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Kullanım Alanları:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Jimnastik - esneklik değerlendirme\n'
                                  '• Dans - hareket kabiliyeti\n'
                                  '• Atletizm - sakatlık riski\n'
                                  '• Genel fitness - esneklik ölçümü',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryTextColor,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sporcu seçimi
                  Text(
                    'Katılımcı Sporcular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (_allAthletes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 48,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz kayıtlı sporcu yok',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allAthletes.length,
                      itemBuilder: (context, index) {
                        final athlete = _allAthletes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '${athlete.name[0]}${athlete.surname[0]}',
                                style: TextStyle(
                                  color: AppTheme.whiteTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text('${athlete.name} ${athlete.surname}'),
                            subtitle: Text('${athlete.branch} • ${athlete.gender}'),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _showMeasurementDialog(athlete),
                              icon: Icon(Icons.straighten, size: 16),
                              label: Text('Test Et'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppTheme.whiteTextColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
} 