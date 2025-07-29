import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class TTestAgilityScreen extends StatefulWidget {
  const TTestAgilityScreen({super.key});

  @override
  State<TTestAgilityScreen> createState() => _TTestAgilityScreenState();
}

class _TTestAgilityScreenState extends State<TTestAgilityScreen> {
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
          '${athlete.name} ${athlete.surname} - T-Test',
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
                      'T şeklinde parkurda ileri-yan-geri koşu kombinasyonu',
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
                  hintText: 'Örn: 10.2',
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
              
              // Performans tahmini
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
                      'Performans Seviyeleri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${athlete.gender == "Erkek" ? "Erkek:" : "Kadın:"} '
                      '${athlete.gender == "Erkek" ? "Mükemmel <9.5s, İyi 9.5-10.5s, Orta 10.5-11.5s" : "Mükemmel <10.5s, İyi 10.5-11.5s, Orta 11.5-12.5s"}',
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
      if (time < 9.5) return "Mükemmel";
      if (time <= 10.5) return "İyi";
      if (time <= 11.5) return "Orta";
      return "Zayıf";
    } else {
      if (time < 10.5) return "Mükemmel";
      if (time <= 11.5) return "İyi";
      if (time <= 12.5) return "Orta";
      return "Zayıf";
    }
  }

  Future<void> _saveResult(AthleteModel athlete, double time, String notes) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final performanceLevel = _getPerformanceLevel(time, athlete.gender);
      
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: 't-test',
        testName: 'T-Test',
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
        title: const Text('T-Test'),
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
                                  Icons.change_history,
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
                                      'T-Test (Çeviklik)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      'Çok Yönlü Hareket ve Çeviklik Testi',
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
                            '1. T şeklinde 4 koni dizilir (10m+5m+5m)\n'
                            '2. A konisinden başla, B konisine koş\n'
                            '3. Sol C konisine shuffle, sağ D konisine shuffle\n'
                            '4. Tekrar B konisine shuffle, A\'ya geri koş\n'
                            '5. Shuffle sırasında ayaklar çaprazlanmaz',
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
                                    'Kurallar: Öne bakış + Ayak çaprazlama yok + Koni dokunma',
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