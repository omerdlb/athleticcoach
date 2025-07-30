import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class TwentyMeterSprintScreen extends StatefulWidget {
  const TwentyMeterSprintScreen({super.key});

  @override
  State<TwentyMeterSprintScreen> createState() => _TwentyMeterSprintScreenState();
}

class _TwentyMeterSprintScreenState extends State<TwentyMeterSprintScreen> {
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
    final timeController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.name} ${athlete.surname} - 20m Sprint',
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
                      'Orta mesafede maksimum hız testi',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tamamlama süresi
              TextField(
                controller: timeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tamamlama Süresi (saniye)',
                  hintText: 'Örn: 3.25',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
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
                      '20m Sprint Norm Değerleri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${athlete.gender == "Erkek" ? "Erkek:" : "Kadın:"} '
                      '${athlete.gender == "Erkek" ? "Mükemmel <3.0s, İyi 3.0-3.3s, Orta 3.3-3.6s" : "Mükemmel <3.3s, İyi 3.3-3.6s, Orta 3.6-3.9s"}',
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
              final time = double.tryParse(timeController.text.replaceAll(',', '.'));
              
              if (time != null && time > 0) {
                Navigator.of(context).pop();
                _saveResult(athlete, time, notesController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen geçerli bir süre girin'),
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

  String _getPerformanceLevel(double time, String gender) {
    if (gender == "Erkek") {
      if (time < 3.0) return "Mükemmel";
      if (time <= 3.3) return "İyi";
      if (time <= 3.6) return "Orta";
      return "Zayıf";
    } else {
      if (time < 3.3) return "Mükemmel";
      if (time <= 3.6) return "İyi";
      if (time <= 3.9) return "Orta";
      return "Zayıf";
    }
  }

  Future<void> _saveResult(AthleteModel athlete, double time, String notes) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final performanceLevel = _getPerformanceLevel(time, athlete.gender);
      
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: '20m-sprint',
        testName: '20m Sprint',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testDate: DateTime.now(),
        result: time,
        resultUnit: 'saniye',
        notes: notes.isNotEmpty ? notes : 'Performans Seviyesi: $performanceLevel',
        sessionId: sessionId,
      );

      await _database.insertTestResult(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - ${time}s ($performanceLevel)'),
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
        title: const Text('20m Sprint Test'),
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
                                  Icons.speed,
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
                                      '20m Sprint Test',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    ),
                                      Text(
                                        'Orta Mesafe Hız Testi',
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
                            '1. 20 metrelik düz bir parkur hazırlanır\n'
                            '2. Başlangıç çizgisinden başla\n'
                            '3. 20 metreyi en kısa sürede koş\n'
                            '4. Bitiş çizgisini geçtiğinde süre durdurulur\n'
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
                                    'Önemli: Maksimum hız + Düz çizgi takibi',
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
                                    Icon(Icons.sports_soccer, size: 16, color: AppTheme.primaryColor),
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
                                  '• Futbol - hızlı hücum\n'
                                  '• Atletizm - sprint performansı\n'
                                  '• Basketbol - fast break\n'
                                  '• Rugby - hız değerlendirme',
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
                              icon: Icon(Icons.timer, size: 16),
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