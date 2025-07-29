import 'dart:math';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class VerticalJumpTestScreen extends StatefulWidget {
  const VerticalJumpTestScreen({super.key});

  @override
  State<VerticalJumpTestScreen> createState() => _VerticalJumpTestScreenState();
}

class _VerticalJumpTestScreenState extends State<VerticalJumpTestScreen> {
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

    final TextEditingController standingReachController = TextEditingController();
    final TextEditingController jumpHeightController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.name} ${athlete.surname} - Dikey Sıçrama Ölçümü',
          style: TextStyle(color: AppTheme.primaryTextColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ayakta uzanma yüksekliği
              TextField(
                controller: standingReachController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Ayakta Uzanma Yüksekliği (cm)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.height, color: AppTheme.primaryColor),
                  helperText: 'Sporcu ayakta dururken parmak uçlarının ulaştığı yükseklik',
                ),
              ),
              const SizedBox(height: 12),
              
              // Sıçrama yüksekliği
              TextField(
                controller: jumpHeightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Sıçrama Yüksekliği (cm)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.trending_up, color: AppTheme.primaryColor),
                  helperText: 'Sıçrama sırasında ulaşılan en yüksek nokta',
                ),
              ),
              const SizedBox(height: 12),
              
              // Kısa protokol bilgisi
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sıçrama Yüksekliği = Sıçrama Noktası - Ayakta Uzanma Yüksekliği',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
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
              final standingReach = double.tryParse(standingReachController.text);
              final jumpHeight = double.tryParse(jumpHeightController.text);
              
              if (standingReach == null || standingReach <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Geçerli bir ayakta uzanma yüksekliği girin'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              if (jumpHeight == null || jumpHeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Geçerli bir sıçrama yüksekliği girin'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              if (jumpHeight <= standingReach) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sıçrama yüksekliği ayakta uzanma yüksekliğinden büyük olmalıdır'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              _saveAthleteResult(athlete, standingReach, jumpHeight);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Kaydet', style: TextStyle(color: AppTheme.whiteTextColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAthleteResult(AthleteModel athlete, double standingReach, double jumpHeight) async {
    // Sıçrama yüksekliğini hesapla
    final verticalJumpHeight = jumpHeight - standingReach;
    
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

    // Güç hesaplama (Takei formülü): P = 21.67 × m × √h
    // m: vücut ağırlığı (kg), h: sıçrama yüksekliği (cm)
    final power = 21.67 * bodyWeight * sqrt(verticalJumpHeight / 100);

    try {
      final result = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testId: 'vertical-jump',
        testName: 'Dikey Sıçrama Testi',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        result: verticalJumpHeight, // Ana sonuç sıçrama yüksekliği
        resultUnit: 'cm',
        testDate: DateTime.now(),
        sessionId: _currentSessionId!,
        notes: 'Ayakta Uzanma: ${standingReach.toStringAsFixed(1)}cm | Sıçrama Noktası: ${jumpHeight.toStringAsFixed(1)}cm | Hesaplanan Güç: ${power.toStringAsFixed(1)} Watt | Ağırlık: ${athlete.weight?.toStringAsFixed(1)}kg',
      );

      await _database.insertTestResult(result);

      setState(() {
        _completedAthletes.add(athlete.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} sonucu kaydedildi - ${verticalJumpHeight.toStringAsFixed(1)} cm'),
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
        title: const Text('Dikey Sıçrama Testi'),
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
                      'Test Protokolü (Sargent Jump)',
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
                  '1. Sporcu duvara yan döner ve ayakta dururken parmak uçlarıyla duvara dokunur',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '2. Bu nokta "ayakta uzanma yüksekliği" olarak işaretlenir',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '3. Sporcu geri çekilir ve maksimum yükseklikte sıçrar',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '4. Sıçrama sırasında ulaştığı en yüksek nokta işaretlenir',
                  style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 13),
                ),
                Text(
                  '5. İki nokta arasındaki fark sıçrama yüksekliğidir',
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
                              'Sıçrama Yüksekliği = Sıçrama Noktası - Ayakta Uzanma Yüksekliği',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Güç = 21.67 × Ağırlık × √Sıçrama Yüksekliği (Watt)',
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
                            '✅ Sıçrama Ölçümü Tamamlandı',
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
                      content: Text('${_selected.length} sporcu dikey sıçrama testi tamamlandı'),
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