import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class CountermovementJumpTestScreen extends StatefulWidget {
  const CountermovementJumpTestScreen({super.key});

  @override
  State<CountermovementJumpTestScreen> createState() => _CountermovementJumpTestScreenState();
}

class _CountermovementJumpTestScreenState extends State<CountermovementJumpTestScreen> {
  final AthleteDatabase _database = AthleteDatabase();
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  Set<String> _completedAthletes = {}; // Testi tamamlayan sporcuların ID'leri
  String? _currentSessionId; // Mevcut test oturumu ID'si

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
      });
    } catch (e) {
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

  void _addJumpData(AthleteModel athlete) {
    // İlk sıçrama verisi ekleniyorsa session ID oluştur
    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final TextEditingController flightTimeController = TextEditingController();
    bool useArmSwing = true; // Varsayılan olarak kol hareketi var
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${athlete.name} ${athlete.surname} - CMJ Ölçümü',
            style: TextStyle(color: AppTheme.primaryTextColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Uçuş süresi girişi
                TextField(
                  controller: flightTimeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Uçuş Süresi (saniye)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                    helperText: 'Sporcu havada kalma süresi (0.5-0.8 saniye arası)',
                    suffixText: 's',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Kol hareketi seçimi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Konfigürasyonu:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: useArmSwing,
                            onChanged: (value) {
                              setDialogState(() {
                                useArmSwing = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Kol hareketi ile (performansı %10+ artırır)',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryTextColor),
                            ),
                          ),
                        ],
                      ),
                      if (!useArmSwing)
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            '• Eller kalçada tutulacak\n• Ek güç için kol kullanımı yasak',
                            style: TextStyle(fontSize: 11, color: AppTheme.secondaryTextColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Kısa protokol bilgisi
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıçrama Yüksekliği = (g × t²) ÷ 8\ng = 9.81 m/s², t = uçuş süresi',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
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
              child: Text('İptal', style: TextStyle(color: AppTheme.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                final flightTime = double.tryParse(flightTimeController.text);
                
                if (flightTime == null || flightTime <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Geçerli bir uçuş süresi girin'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                
                if (flightTime > 1.0 || flightTime < 0.3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Uçuş süresi 0.3-1.0 saniye aralığında olmalıdır'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                _saveAthleteResult(athlete, flightTime, useArmSwing);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: Text('Kaydet', style: TextStyle(color: AppTheme.whiteTextColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAthleteResult(AthleteModel athlete, double flightTime, bool useArmSwing) async {
    // Vücut ağırlığı kontrolü
    final bodyWeight = athlete.weight ?? 0.0;
    if (bodyWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${athlete.name} ${athlete.surname} için vücut ağırlığı girilmemiş'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Sıçrama yüksekliği hesaplama: h = (g × t²) ÷ 8
    // g = 9.81 m/s², t = uçuş süresi (saniye)
    const double gravity = 9.81;
    final jumpHeight = (gravity * flightTime * flightTime) / 8;
    final jumpHeightCm = jumpHeight * 100; // metreyi cm'ye çevir

    // Güç hesaplama (Bosco formülü): P = (m × g × h × 60) / t
    // m: vücut ağırlığı (kg), h: sıçrama yüksekliği (m), t: uçuş süresi (s)
    final power = (bodyWeight * gravity * jumpHeight * 60) / flightTime;

    try {
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: 'cmj',
        testName: 'Countermovement Jump (CMJ)',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        result: jumpHeightCm, // Ana sonuç sıçrama yüksekliği (cm)
        resultUnit: 'cm',
        testDate: DateTime.now(),
        sessionId: _currentSessionId!,
        notes: 'Uçuş Süresi: ${flightTime.toStringAsFixed(3)}s | Sıçrama Yüksekliği: ${jumpHeightCm.toStringAsFixed(1)}cm | Güç: ${power.toStringAsFixed(1)} W | Kol Hareketi: ${useArmSwing ? "Var" : "Yok"} | Ağırlık: ${athlete.weight?.toStringAsFixed(1)}kg',
      );

      await _database.insertTestResult(result);

      setState(() {
        _completedAthletes.add(athlete.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} sonucu kaydedildi - ${jumpHeightCm.toStringAsFixed(1)} cm'),
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
        title: const Text('Countermovement Jump (CMJ)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Protokol bilgisi
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'CMJ Test Protokolü',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Sporcu test platformuna ayakları omuz genişliğinde diker',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '2. Kısa bir "countermovement" (ön-germe) hareketi yapar',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '3. Maksimum yükseklikte sıçrar ve aynı noktaya iner',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '4. Uçuş sırasında kalça, diz ve ayak bileği ekstansiyonda tutulur',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '5. Minimum 3 deneme yapılır, en iyi sonuç alınır',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sıçrama Yüksekliği = (9.81 × t²) ÷ 8 (m)',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Güç = (m × 9.81 × h × 60) ÷ t (Watt)',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sporcu seçimi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allAthletes.length,
              itemBuilder: (context, index) {
                final athlete = _allAthletes[index];
                final isSelected = _selected.contains(athlete);
                final isCompleted = _completedAthletes.contains(athlete.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCompleted ? AppTheme.successColor : (isSelected ? AppTheme.primaryColor : AppTheme.borderColor),
                      width: isCompleted ? 2 : (isSelected ? 2 : 1),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted ? AppTheme.successColor : AppTheme.primaryColor,
                      child: isCompleted 
                        ? Icon(Icons.check, color: AppTheme.whiteTextColor, size: 20)
                        : Text(
                            '${athlete.name[0]}${athlete.surname[0]}',
                            style: TextStyle(
                              color: AppTheme.whiteTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    title: Text(
                      '${athlete.name} ${athlete.surname}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vücut Ağırlığı: ${athlete.weight?.toStringAsFixed(1) ?? "Girilmemiş"} kg',
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        ),
                        if (isCompleted)
                          Text(
                            '✅ CMJ Testi Tamamlandı',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && !isCompleted)
                          ElevatedButton(
                            onPressed: () => _addJumpData(athlete),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: Text(
                              'Ölçüm Ekle',
                              style: TextStyle(
                                color: AppTheme.whiteTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(athlete);
                              } else {
                                _selected.remove(athlete);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Tamamla butonu
          if (_selected.isNotEmpty && _selected.every((athlete) => _completedAthletes.contains(athlete.id)))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_selected.length} sporcu CMJ testi tamamlandı'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Testi Tamamla',
                  style: TextStyle(
                    color: AppTheme.whiteTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 