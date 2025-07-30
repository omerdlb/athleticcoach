import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class BalkeTestScreen extends StatefulWidget {
  const BalkeTestScreen({super.key});

  @override
  State<BalkeTestScreen> createState() => _BalkeTestScreenState();
}

class _BalkeTestScreenState extends State<BalkeTestScreen> {
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
    final distanceController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.name} ${athlete.surname} - Balke Test',
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
                      'Kardiyovasküler dayanıklılık testi',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Koşulan mesafe
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Koşulan Mesafe (metre)',
                  hintText: 'Örn: 2500',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_run, color: AppTheme.primaryColor),
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
                      'Balke Test Norm Değerleri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${athlete.gender == "Erkek" ? "Erkek:" : "Kadın:"} '
                      '${athlete.gender == "Erkek" ? "Mükemmel >3000m, İyi 2500-3000m, Orta 2000-2500m" : "Mükemmel >2500m, İyi 2000-2500m, Orta 1500-2000m"}',
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
              final distance = double.tryParse(distanceController.text.replaceAll(',', '.'));
              
              if (distance != null && distance > 0) {
                Navigator.of(context).pop();
                _saveResult(athlete, distance, notesController.text);
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

  String _getPerformanceLevel(double distance, String gender) {
    if (gender == "Erkek") {
      if (distance > 3000) return "Mükemmel";
      if (distance >= 2500) return "İyi";
      if (distance >= 2000) return "Orta";
      return "Zayıf";
    } else {
      if (distance > 2500) return "Mükemmel";
      if (distance >= 2000) return "İyi";
      if (distance >= 1500) return "Orta";
      return "Zayıf";
    }
  }

  Future<void> _saveResult(AthleteModel athlete, double distance, String notes) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final performanceLevel = _getPerformanceLevel(distance, athlete.gender);
      
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: 'balke-test',
        testName: 'Balke Test',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testDate: DateTime.now(),
        result: distance,
        resultUnit: 'metre',
        notes: notes.isNotEmpty ? notes : 'Performans Seviyesi: $performanceLevel',
        sessionId: sessionId,
      );

      await _database.insertTestResult(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - ${distance}m ($performanceLevel)'),
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
        title: const Text('Balke Test'),
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
                                  Icons.directions_run,
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
                                      'Balke Test',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    ),
                                      Text(
                                        'Kardiyovasküler Dayanıklılık Testi',
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
                            '1. 400 metrelik bir koşu pisti hazırlanır\n'
                            '2. 15 dakika süreyle maksimum hızda koş\n'
                            '3. Koşulan toplam mesafe ölçülür\n'
                            '4. Hız sabit tutulmaya çalışılır\n'
                            '5. Test süresi 15 dakika ile sınırlıdır',
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
                                    'Önemli: Sabit hız + 15 dakika süre',
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
                                    Icon(Icons.fitness_center, size: 16, color: AppTheme.primaryColor),
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
                                  '• Atletizm - dayanıklılık değerlendirme\n'
                                  '• Futbol - kardiyovasküler fitness\n'
                                  '• Basketbol - dayanıklılık ölçümü\n'
                                  '• Genel fitness - VO2max tahmini',
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
                              icon: Icon(Icons.directions_run, size: 16),
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