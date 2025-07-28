import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CooperTestScreen extends StatefulWidget {
  const CooperTestScreen({super.key});

  @override
  State<CooperTestScreen> createState() => _CooperTestScreenState();
}

class _CooperTestScreenState extends State<CooperTestScreen> {
  // Test state
  bool _isRunning = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _testTimer;
  
  // Athletes
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  List<AthleteModel> _active = [];
  List<AthleteModel> _paused = []; // Testi bırakan ama mesafe girilmemiş sporcular
  Map<String, double> _athleteDistances = {}; // athleteId -> distance in meters
  Map<String, bool> _failed = {}; // athleteId -> eliminated
  Map<String, bool> _completed = {}; // athleteId -> completed with distance
  
  // Database
  final AthleteDatabase _db = AthleteDatabase();

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    try {
      final athletes = await _db.getAllAthletes();
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

  void _startTest() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen en az bir sporcu seçin'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _active = List.from(_selected);
      _athleteDistances = {for (var a in _active) a.id: 0.0};
      _failed = {for (var a in _active) a.id: false};
      _completed = {for (var a in _active) a.id: false};
    });

    _startTimers();
  }

  void _startTimers() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
        
        // Test süresi dolduğunda otomatik bitir
        if (_elapsedSeconds >= 720) { // 12 dakika = 720 saniye
          _stopTest();
        }
      }
    });
  }

  void _pauseTest() {
    setState(() {
      _isPaused = true;
    });
    _testTimer?.cancel();
  }

  void _resumeTest() {
    setState(() {
      _isPaused = false;
    });
    _startTimers();
  }

  void _stopTest() {
    _testTimer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
    _saveResults();
  }

  void _failAthlete(AthleteModel athlete) {
    setState(() {
      _failed[athlete.id] = true;
      _active.remove(athlete);
      _paused.add(athlete); // Testi bırakan sporcuları pasife al
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${athlete.name} ${athlete.surname} testi bıraktı - Mesafe girişi bekleniyor'),
        backgroundColor: AppTheme.warningColor,
      ),
    );

    // Tüm sporcular bıraktıysa testi bitir
    if (_active.isEmpty && _paused.isEmpty) {
      _stopTest();
    }
  }

  void _completeAthlete(AthleteModel athlete) {
    final distance = _athleteDistances[athlete.id] ?? 0.0;
    if (distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen ${athlete.name} ${athlete.surname} için mesafe girin'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _completed[athlete.id] = true;
      _paused.remove(athlete);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${athlete.name} ${athlete.surname} tamamlandı'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Tüm sporcular tamamlandıysa testi bitir
    if (_active.isEmpty && _paused.isEmpty) {
      _stopTest();
    }
  }

  void _updateDistance(AthleteModel athlete, double distance) {
    setState(() {
      _athleteDistances[athlete.id] = distance;
      _completed[athlete.id] = true; // Mesaj girildiğinde tamamlandı olarak işaretle
    });
  }

  Future<void> _saveResults() async {
    final now = DateTime.now();
    final testId = '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(now)}_${now.millisecondsSinceEpoch}';
    final sessionId = '${testId}_0';

    for (final athlete in _selected) {
      final distance = _athleteDistances[athlete.id] ?? 0.0;
      final isFailed = _failed[athlete.id] ?? false;
      final isCompleted = _completed[athlete.id] ?? false;
      
      // VO2max hesaplama: VO2max (ml/kg/min) = (22.351 x distance in kilometers) - 11.288
      final distanceKm = distance / 1000;
      final vo2max = (22.351 * distanceKm) - 11.288;
      
      final res = TestResultModel(
        id: '${testId}_${athlete.id}',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testName: 'Cooper 12 Dakika Koşu Testi',
        testId: testId,
        sessionId: sessionId,
        result: distance,
        resultUnit: 'metre',
        testDate: now,
        notes: isFailed ? 'Testi bıraktı' : isCompleted ? 'Tamamlandı. Tahmini VO2max: ${vo2max.toStringAsFixed(1)} ml/kg/min' : 'Mesafe girilmedi',
      );
      await _db.insertTestResult(res);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sonuçlar kaydedildi'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getPerformanceCategory(double distance, String gender, int age) {
    // Yaş grubunu belirle
    int ageGroup;
    if (age < 30) ageGroup = 20;
    else if (age < 40) ageGroup = 30;
    else if (age < 50) ageGroup = 40;
    else ageGroup = 50;

    // Performans kategorileri (Training Station sitesinden alınan veriler)
    if (gender.toLowerCase() == 'erkek' || gender.toLowerCase() == 'male') {
      if (ageGroup == 20) {
        if (distance >= 2800) return 'Mükemmel';
        else if (distance >= 2400) return 'Ortalamanın Üstü';
        else if (distance >= 2200) return 'Ortalama';
        else if (distance >= 1600) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else if (ageGroup == 30) {
        if (distance >= 2700) return 'Mükemmel';
        else if (distance >= 2300) return 'Ortalamanın Üstü';
        else if (distance >= 1900) return 'Ortalama';
        else if (distance >= 1500) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else if (ageGroup == 40) {
        if (distance >= 2500) return 'Mükemmel';
        else if (distance >= 2100) return 'Ortalamanın Üstü';
        else if (distance >= 1700) return 'Ortalama';
        else if (distance >= 1400) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else { // 50+
        if (distance >= 2400) return 'Mükemmel';
        else if (distance >= 2000) return 'Ortalamanın Üstü';
        else if (distance >= 1600) return 'Ortalama';
        else if (distance >= 1300) return 'Ortalamanın Altı';
        else return 'Zayıf';
      }
    } else { // Kadın
      if (ageGroup == 20) {
        if (distance >= 2700) return 'Mükemmel';
        else if (distance >= 2200) return 'Ortalamanın Üstü';
        else if (distance >= 1800) return 'Ortalama';
        else if (distance >= 1500) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else if (ageGroup == 30) {
        if (distance >= 2500) return 'Mükemmel';
        else if (distance >= 2000) return 'Ortalamanın Üstü';
        else if (distance >= 1700) return 'Ortalama';
        else if (distance >= 1400) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else if (ageGroup == 40) {
        if (distance >= 2300) return 'Mükemmel';
        else if (distance >= 1900) return 'Ortalamanın Üstü';
        else if (distance >= 1500) return 'Ortalama';
        else if (distance >= 1200) return 'Ortalamanın Altı';
        else return 'Zayıf';
      } else { // 50+
        if (distance >= 2200) return 'Mükemmel';
        else if (distance >= 1700) return 'Ortalamanın Üstü';
        else if (distance >= 1400) return 'Ortalama';
        else if (distance >= 1100) return 'Ortalamanın Altı';
        else return 'Zayıf';
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooper 12 Dakika Koşu Testi'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
      ),
      body: Column(
        children: [
          _buildStatus(),
          if (!_isRunning) _buildSelection(),
          if (_isRunning) ...[
            if (_active.isNotEmpty) _buildActive(),
            if (_paused.isNotEmpty) _buildPaused(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final remainingTime = 720 - _elapsedSeconds;
    final progress = _elapsedSeconds / 720;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          if (_isRunning) ...[
            Text(
              'KALAN SÜRE',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(remainingTime > 0 ? remainingTime : 0),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Aktif: ${_active.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Duraklatılmış: ${_paused.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ] else ...[
            Text(
              'HAZIR',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '12:00',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 12),
          if (!_isRunning)
            ElevatedButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isPaused)
                  ElevatedButton.icon(
                    onPressed: _pauseTest,
                    icon: const Icon(Icons.pause),
                    label: const Text('Duraklat'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _resumeTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Devam'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _stopTest,
                  icon: const Icon(Icons.stop),
                  label: const Text('Bitir'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelection() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sporcu Seçimi',
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allAthletes.length,
              itemBuilder: (context, index) {
                final athlete = _allAthletes[index];
                final isSelected = _selected.contains(athlete);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CheckboxListTile(
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
                    title: Text('${athlete.name} ${athlete.surname}'),
                    subtitle: Text('${_calculateAge(athlete.birthDate)} yaş • ${athlete.gender}'),
                    secondary: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        '${athlete.name[0]}${athlete.surname[0]}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActive() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Aktif Sporcular',
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _active.length,
              itemBuilder: (context, index) {
                final athlete = _active[index];
                final distance = _athleteDistances[athlete.id] ?? 0.0;
                final distanceKm = distance / 1000;
                final vo2max = (22.351 * distanceKm) - 11.288;
                                 final category = _getPerformanceCategory(distance, athlete.gender, _calculateAge(athlete.birthDate));
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '${athlete.name[0]}${athlete.surname[0]}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${athlete.name} ${athlete.surname}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                                                     Text(
                                     '${_calculateAge(athlete.birthDate)} yaş • ${athlete.gender}',
                                     style: TextStyle(
                                       color: AppTheme.secondaryTextColor,
                                       fontSize: 14,
                                     ),
                                   ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.stop, color: AppTheme.errorColor),
                              onPressed: () => _failAthlete(athlete),
                              tooltip: 'Testi Bırak',
                            ),
                            IconButton(
                              icon: Icon(Icons.check_circle, color: AppTheme.successColor),
                              onPressed: () => _completeAthlete(athlete),
                              tooltip: 'Tamamla',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mesafe',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${distance.toStringAsFixed(0)}m',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tahmini VO2max',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${vo2max.toStringAsFixed(1)} ml/kg/min',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kategori',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Mesafe (metre)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final newDistance = double.tryParse(value) ?? 0.0;
                                  _updateDistance(athlete, newDistance);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaused() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Duraklatılmış Sporcular',
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _paused.length,
              itemBuilder: (context, index) {
                final athlete = _paused[index];
                final distance = _athleteDistances[athlete.id] ?? 0.0;
                final distanceKm = distance / 1000;
                final vo2max = (22.351 * distanceKm) - 11.288;
                final category = _getPerformanceCategory(distance, athlete.gender, _calculateAge(athlete.birthDate));

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '${athlete.name[0]}${athlete.surname[0]}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${athlete.name} ${athlete.surname}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${_calculateAge(athlete.birthDate)} yaş • ${athlete.gender}',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.play_arrow, color: AppTheme.successColor),
                              onPressed: () => _resumeAthlete(athlete),
                              tooltip: 'Sporcuyu Aktif Et',
                            ),
                            IconButton(
                              icon: Icon(Icons.check_circle, color: AppTheme.successColor),
                              onPressed: () => _completeAthlete(athlete),
                              tooltip: 'Tamamla',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mesafe',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${distance.toStringAsFixed(0)}m',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tahmini VO2max',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${vo2max.toStringAsFixed(1)} ml/kg/min',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kategori',
                                    style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Mesafe (metre)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final newDistance = double.tryParse(value) ?? 0.0;
                                  _updateDistance(athlete, newDistance);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resumeAthlete(AthleteModel athlete) {
    setState(() {
      _paused.remove(athlete);
      _active.add(athlete);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${athlete.name} ${athlete.surname} aktif edildi.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Mükemmel':
        return Colors.green;
      case 'Ortalamanın Üstü':
        return Colors.blue;
      case 'Ortalama':
        return Colors.orange;
      case 'Ortalamanın Altı':
        return Colors.deepOrange;
      case 'Zayıf':
        return Colors.red;
      default:
        return AppTheme.primaryTextColor;
    }
  }
} 