import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';

class MargariaTestScreen extends StatefulWidget {
  const MargariaTestScreen({super.key});

  @override
  State<MargariaTestScreen> createState() => _MargariaTestScreenState();
}

class _MargariaTestScreenState extends State<MargariaTestScreen> {
  final AthleteDatabase _database = AthleteDatabase();
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  Set<String> _completedAthletes = {}; // Süresi eklenen sporcuların ID'leri
  String? _currentSessionId; // Mevcut test oturumu ID'si
  
  // Test parametreleri (Wikipedia'dan)
  static const double stepHeight = 17.8; // cm (7 inches)
  static const int stepsBetween = 6; // 3. ve 9. basamak arası
  static const double totalHeight = stepHeight * stepsBetween; // cm
  static const double gravity = 9.81; // m/s²

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

  void _addTimeData(AthleteModel athlete) {
    // İlk süre ekleniyorsa session ID oluştur
    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final TextEditingController timeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.name} ${athlete.surname} - Süre Girişi',
          style: TextStyle(color: AppTheme.primaryTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '3. ve 9. basamak arası süreyi girin (saniye cinsinden)',
              style: TextStyle(color: AppTheme.primaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Süre (saniye)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 8),
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
                    'Test Protokolü:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 6m mesafeden koşarak gel',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryTextColor),
                  ),
                  Text(
                    '• 3. basamaktan 9. basamağa çık',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryTextColor),
                  ),
                  Text(
                    '• 3. ve 9. basamak arası süreyi ölç',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              final time = double.tryParse(timeController.text);
              if (time == null || time <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Geçerli bir süre girin'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _saveAthleteResult(athlete, time);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Kaydet', style: TextStyle(color: AppTheme.whiteTextColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAthleteResult(AthleteModel athlete, double time) async {
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

    // Güç hesaplama: P = (m * g * h) / t
    final power = (bodyWeight * gravity * (totalHeight / 100)) / time;

    try {
              final result = TestResultModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          testId: 'margaria',
          testName: 'Margaria-Kalamen Testi',
          athleteId: athlete.id,
          athleteName: athlete.name,
          athleteSurname: athlete.surname,
          result: power,
          resultUnit: 'Watt',
          testDate: DateTime.now(),
          sessionId: _currentSessionId!,
          notes: 'Süre: ${time.toStringAsFixed(2)}s | Yükseklik: ${(totalHeight/100).toStringAsFixed(2)}m | Ağırlık: ${athlete.weight?.toStringAsFixed(1)}kg',
        );

              await _database.insertTestResult(result);

        setState(() {
          _completedAthletes.add(athlete.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${athlete.name} ${athlete.surname} sonucu kaydedildi - ${power.toStringAsFixed(1)} Watt'),
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
        title: const Text('Margaria-Kalamen Testi'),
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
                      'Test Protokolü',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 9 basamaklı merdiven hazırlanır',
                  style: TextStyle(color: AppTheme.primaryTextColor),
                ),
                Text(
                  '• 3. ve 9. basamaklar işaretlenir',
                  style: TextStyle(color: AppTheme.primaryTextColor),
                ),
                Text(
                  '• 6m mesafeden koşarak gelir',
                  style: TextStyle(color: AppTheme.primaryTextColor),
                ),
                Text(
                  '• 3. basamaktan 9. basamağa çıkar',
                  style: TextStyle(color: AppTheme.primaryTextColor),
                ),
                Text(
                  '• 3. ve 9. basamak arası süre ölçülür',
                  style: TextStyle(color: AppTheme.primaryTextColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Güç = (Ağırlık × 9.81 × Yükseklik) ÷ Süre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: 12,
                    ),
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
                            '✅ Süre Eklendi',
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
                            onPressed: () => _addTimeData(athlete),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: Text(
                              'Süre Ekle',
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
                      content: Text('${_selected.length} sporcu sonucu aynı oturumda kaydedildi'),
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
                  'Tamamla',
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