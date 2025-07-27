import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class YoYoTestScreen extends StatefulWidget {
  const YoYoTestScreen({super.key});

  @override
  State<YoYoTestScreen> createState() => _YoYoTestScreenState();
}

class _YoYoTestScreenState extends State<YoYoTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _restAudioPlayer = AudioPlayer();
  final AthleteDatabase _database = AthleteDatabase();
  
  // Test durumu
  bool _isTestRunning = false;
  bool _isTestPaused = false;
  int _currentLevel = 1;
  int _currentShuttle = 1;
  int _totalShuttles = 8; // Her seviyede 8 mekik (20m gidiş + 20m geliş)
  int _elapsedSeconds = 0;
  bool _isRestPeriod = false; // Dinlenme dönemi mi?
  int _restCountdown = 0; // Dinlenme geri sayımı
  bool _skipNextShuttleAdvance = false;
  bool _pendingLevelUp = false;
  
  // Sporcu listesi
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selectedAthletes = [];
  List<AthleteModel> _activeAthletes = [];
  Map<String, int> _athleteLevels = {}; // Sporcu ID -> Seviye
  Map<String, int> _athleteShuttles = {}; // Sporcu ID -> Mekik
  Map<String, int> _athleteWarnings = {}; // Sporcu ID -> Uyarı sayısı
  Map<String, bool> _athleteFailed = {}; // Sporcu ID -> Başarısız mı?
  
  // Timer
  Timer? _testTimer;
  Timer? _beepTimer;
  Timer? _restTimer;
  
  // Yo-Yo IR1 seviye verileri (saniye cinsinden bip aralıkları)
  final Map<int, double> _levelIntervals = {
    1: 9.0, 2: 9.0, 3: 9.0, 4: 9.0, 5: 9.0, 6: 9.0, 7: 9.0, 8: 9.0,
    9: 8.0, 10: 8.0, 11: 8.0, 12: 8.0, 13: 8.0, 14: 8.0, 15: 8.0, 16: 8.0,
    17: 7.0, 18: 7.0, 19: 7.0, 20: 7.0, 21: 7.0, 22: 7.0, 23: 7.0, 24: 7.0,
    25: 6.0, 26: 6.0, 27: 6.0, 28: 6.0, 29: 6.0, 30: 6.0, 31: 6.0, 32: 6.0,
    33: 5.0, 34: 5.0, 35: 5.0, 36: 5.0, 37: 5.0, 38: 5.0, 39: 5.0, 40: 5.0,
    41: 4.0, 42: 4.0, 43: 4.0, 44: 4.0, 45: 4.0, 46: 4.0, 47: 4.0, 48: 4.0,
    49: 3.0, 50: 3.0, 51: 3.0, 52: 3.0, 53: 3.0, 54: 3.0, 55: 3.0, 56: 3.0,
    57: 2.0, 58: 2.0, 59: 2.0, 60: 2.0, 61: 2.0, 62: 2.0, 63: 2.0, 64: 2.0,
  };

  @override
  void initState() {
    super.initState();
    _loadAthletes();
    _initializeAudio();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _beepTimer?.cancel();
    _restTimer?.cancel();
    _audioPlayer.dispose();
    _restAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    final athletes = await _database.getAllAthletes();
    setState(() {
      _allAthletes = athletes;
    });
  }

  Future<void> _initializeAudio() async {
    // Bip sesi için hazırlık
    try {
      await _audioPlayer.setSource(AssetSource('sounds/yoyobeepsound.mp3'));
      await _restAudioPlayer.setSource(AssetSource('sounds/yoyorestsound.mp3'));
      print('Yo-Yo sesleri yüklendi');
    } catch (e) {
      print('Ses dosyası yüklenemedi: $e');
    }
  }

  void _startTest() {
    if (_selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen en az bir sporcu seçin'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isTestRunning = true;
      _isTestPaused = false;
      _currentLevel = 1;
      _currentShuttle = 1;
      _elapsedSeconds = 0;
      _isRestPeriod = false;
      _restCountdown = 0;
      _activeAthletes = List.from(_selectedAthletes);
      
      // Sporcu durumlarını sıfırla
      for (final athlete in _activeAthletes) {
        _athleteLevels[athlete.id] = 1;
        _athleteShuttles[athlete.id] = 1;
        _athleteWarnings[athlete.id] = 0;
        _athleteFailed[athlete.id] = false;
      }
      
      print('Yo-Yo IR1 testi başladı - ${_activeAthletes.length} sporcu ile');
      print('İlk seviye bip aralığı: ${_levelIntervals[1]} saniye');
      print('Her 40m (2 mekik) sonrası 10 saniye dinlenme');
    });

    _startTimer();
    _startBeepSequence();
  }

  void _pauseTest() {
    setState(() {
      _isTestPaused = true;
    });
    _testTimer?.cancel();
    _beepTimer?.cancel();
  }

  void _resumeTest() {
    setState(() {
      _isTestPaused = false;
    });
    _startTimer();
    _startBeepSequence();
  }

  void _stopTest() {
    setState(() {
      _isTestRunning = false;
      _isTestPaused = false;
    });
    _testTimer?.cancel();
    _beepTimer?.cancel();
    _saveResults();
  }

  void _startTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTestPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _startBeepSequence() {
    _playBeep();
    _scheduleNextBeep();
  }

  void _playBeep() {
    // Bip sesi çal
    try {
      _audioPlayer.play(AssetSource('sounds/yoyobeepsound.mp3'));
      print('Yo-Yo bip sesi çalındı - Seviye: $_currentLevel, Mekik: $_currentShuttle');
    } catch (e) {
      print('Bip sesi çalınamadı: $e');
    }
  }

  void _playRestSound() {
    // Dinlenme sesi çal
    try {
      _restAudioPlayer.play(AssetSource('sounds/yoyorestsound.mp3'));
      print('Dinlenme sesi çalındı - 10 saniye dinlenme');
    } catch (e) {
      print('Dinlenme sesi çalınamadı: $e');
    }
  }

  void _scheduleNextBeep() {
    if (!_isTestRunning || _isTestPaused || _isRestPeriod) return;

    final interval = _levelIntervals[_currentLevel] ?? 2.0;
    _beepTimer = Timer(Duration(milliseconds: (interval * 1000).round()), () {
              if (_isTestRunning && !_isTestPaused && !_isRestPeriod) {
          _playBeep();
          if (_skipNextShuttleAdvance) {
            print('DEBUG: Mekik artırma atlandı, _skipNextShuttleAdvance = true');
            _skipNextShuttleAdvance = false;
          } else {
            _advanceShuttle();
          }
          _scheduleNextBeep();
        }
    });
  }

  void _advanceShuttle() {
    setState(() {
      // Dinlenme kontrolü: mevcut mekik çift ise dinlenme
      if (_currentShuttle % 2 == 0) {
        // Seviye atlama gerekecek mi?
        _pendingLevelUp = _currentShuttle == _totalShuttles;
        _startRestPeriod();
        return;
      }

      // Dinlenme yoksa normal ilerle
      if (_currentShuttle == _totalShuttles) {
        // Seviye atla
        _currentLevel++;
        _currentShuttle = 1;
        for (final athlete in _activeAthletes) {
          _athleteLevels[athlete.id] = _currentLevel;
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
        print('Seviye $_currentLevel başladı - Bip aralığı: ${_levelIntervals[_currentLevel]} saniye');
      } else {
        // Sadece mekik artır
        _currentShuttle++;
        for (final athlete in _activeAthletes) {
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
      }
      print('DEBUG: Mekik $_currentShuttle/$_totalShuttles - Seviye $_currentLevel');
    });
  }

  void _startRestPeriod() {
    setState(() {
      _isRestPeriod = true;
      _restCountdown = 10; // 10 saniye dinlenme
      _skipNextShuttleAdvance = true; // Dinlenme sonrası ilk bipte mekik artırılmasın
    });
    
    _playRestSound();
    
    // Antrenör yönergesi
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 DİNLENME DÖNEMİ - 10 saniye yavaş yürüyüş'),
          backgroundColor: AppTheme.secondaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    // Dinlenme geri sayımı
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTestPaused) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _restCountdown--;
      });
      
      if (_restCountdown <= 0) {
        timer.cancel();
        _endRestPeriod();
      }
    });
  }

  void _endRestPeriod() {
    setState(() {
      _isRestPeriod = false;
      _restCountdown = 0;
      if (_pendingLevelUp) {
        _currentLevel++;
        _currentShuttle = 1;
        for (final athlete in _activeAthletes) {
          _athleteLevels[athlete.id] = _currentLevel;
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
        _pendingLevelUp = false;
        print('Seviye $_currentLevel başladı - Bip aralığı: ${_levelIntervals[_currentLevel]} saniye');
      } else {
        // Dinlenme sonrası bir sonraki mekik (çift sonrası -> tek)
        _currentShuttle++;
        for (final athlete in _activeAthletes) {
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
      }
    });

    // Antrenör yönergesi
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏃‍♂️ DİNLENME BİTTİ - Koşmaya devam edin'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Dinlenme sonrası yeni mekik için bip
    _playBeep();
    _scheduleNextBeep();
  }

  void _markAthleteWarning(String athleteId) {
    setState(() {
      _athleteWarnings[athleteId] = (_athleteWarnings[athleteId] ?? 0) + 1;
      
      if (_athleteWarnings[athleteId]! >= 2) {
        _markAthleteFailed(athleteId);
      }
    });
  }

  void _markAthleteFailed(String athleteId) {
    setState(() {
      _athleteFailed[athleteId] = true;
      _activeAthletes.removeWhere((athlete) => athlete.id == athleteId);
    });
  }

    Future<void> _saveResults() async {
    final now = DateTime.now();
    final sessionId = now.millisecondsSinceEpoch.toString();
    int savedCount = 0;
    
    for (final athlete in _selectedAthletes) {
      final level = _athleteLevels[athlete.id] ?? 1;
      final shuttle = _athleteShuttles[athlete.id] ?? 1;
      final failed = _athleteFailed[athlete.id] ?? false;
      final warnings = _athleteWarnings[athlete.id] ?? 0;
      
      // Başarısız olan sporcular için seviye - 1, başarılı olanlar için mevcut seviye
      final finalLevel = failed ? (level - 1) : level;
      
      // Detaylı notlar oluştur
      final distanceForAthlete = _calculateDistance(failed?level-1:level, shuttle);
      final vo2ForAthlete = _calculateVo2(distanceForAthlete);
      final detailNotes = '${failed ? 'Başarısız • ' : ''}Mesafe ${distanceForAthlete} m • VO2 ${vo2ForAthlete.toStringAsFixed(1)}';
      
      final result = TestResultModel(
        id: '${athlete.id}_${sessionId}_${savedCount}',
        testId: 'yo-yo-ir1',
        testName: 'Yo-Yo Intermittent Recovery Test Level 1',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testDate: now,
        result: distanceForAthlete.toDouble(),
        resultUnit: 'metre',
        notes: detailNotes,
        aiAnalysis: null, // AI analizi daha sonra yapılabilir
        sessionId: sessionId,
      );
      
      try {
        await _database.insertTestResult(result);
        savedCount++;
        print('${athlete.name} ${athlete.surname} sonucu kaydedildi: Seviye $finalLevel');
      } catch (e) {
        print('${athlete.name} ${athlete.surname} sonucu kaydedilemedi: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount sporcu sonucu başarıyla kaydedildi'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _calculateDistance(int level,int shuttle){
    return (((level-1)*8)+(shuttle-1))*40+40; // her mekik 40m, shuttle 1 dahil
  }
  double _calculateVo2(int distance){
    return 36.4+0.0084*distance; // Yo-Yo IR1 VO2 tahmini formülü
  }

  String _formatDateTime(DateTime dt){
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yo-Yo IR1 Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Test durumu ve kontroller
          _buildTestStatusSection(),
          
          // Sporcu seçimi (test başlamadan önce)
          if (!_isTestRunning) _buildAthleteSelectionSection(),
          
          // Aktif sporcu listesi (test sırasında)
          if (_isTestRunning) _buildActiveAthletesSection(),
          
          // Test sonuçları (test bittikten sonra)
          if (!_isTestRunning && _selectedAthletes.isNotEmpty) _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildTestStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Test durumu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTestRunning 
                    ? (_isRestPeriod ? 'DİNLENME DÖNEMİ' : 'TEST DEVAM EDİYOR')
                    : 'TEST HAZIR',
                style: TextStyle(
                  color: AppTheme.whiteTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.whiteTextColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_activeAthletes.length} Aktif',
                  style: TextStyle(
                    color: AppTheme.whiteTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Timer ve seviye bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timer
              Column(
                children: [
                  Icon(
                    Icons.timer,
                    color: AppTheme.whiteTextColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: TextStyle(
                      color: AppTheme.whiteTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Süre',
                    style: TextStyle(
                      color: AppTheme.whiteTextColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Seviye
              Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.whiteTextColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_currentLevel',
                    style: TextStyle(
                      color: AppTheme.whiteTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Seviye',
                    style: TextStyle(
                      color: AppTheme.whiteTextColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Mekik
              Column(
                children: [
                  Icon(
                    Icons.repeat,
                    color: AppTheme.whiteTextColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_currentShuttle/$_totalShuttles',
                    style: TextStyle(
                      color: AppTheme.whiteTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mekik',
                    style: TextStyle(
                      color: AppTheme.whiteTextColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Dinlenme durumu
          if (_isRestPeriod)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pause_circle,
                    color: AppTheme.secondaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        'DİNLENME DÖNEMİ',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_restCountdown saniye kaldı',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Kontrol butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isTestRunning)
                ElevatedButton.icon(
                  onPressed: _startTest,
                  icon: Icon(Icons.play_arrow, color: AppTheme.whiteTextColor),
                  label: Text('Testi Başlat', style: TextStyle(color: AppTheme.whiteTextColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              if (_isTestRunning && !_isTestPaused)
                ElevatedButton.icon(
                  onPressed: _pauseTest,
                  icon: Icon(Icons.pause, color: AppTheme.whiteTextColor),
                  label: Text('Duraklat', style: TextStyle(color: AppTheme.whiteTextColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              if (_isTestRunning && _isTestPaused)
                ElevatedButton.icon(
                  onPressed: _resumeTest,
                  icon: Icon(Icons.play_arrow, color: AppTheme.whiteTextColor),
                  label: Text('Devam Et', style: TextStyle(color: AppTheme.whiteTextColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              if (_isTestRunning)
                ElevatedButton.icon(
                  onPressed: _stopTest,
                  icon: Icon(Icons.stop, color: AppTheme.whiteTextColor),
                  label: Text('Bitir', style: TextStyle(color: AppTheme.whiteTextColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteSelectionSection() {
    return Expanded(
      child: Column(
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Sporcu Seçimi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedAthletes.length} seçili',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Sporcu listesi
          Expanded(
            child: ListView.builder(
              itemCount: _allAthletes.length,
              itemBuilder: (context, index) {
                final athlete = _allAthletes[index];
                final isSelected = _selectedAthletes.contains(athlete);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.secondaryColor,
                      child: Text(
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
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      '${athlete.branch} • ${DateTime.now().year - athlete.birthDate.year} yaş',
                      style: TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedAthletes.add(athlete);
                          } else {
                            _selectedAthletes.remove(athlete);
                          }
                        });
                      },
                      activeColor: AppTheme.primaryColor,
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

  Widget _buildActiveAthletesSection() {
    return Expanded(
      child: Column(
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Aktif Sporcular',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_activeAthletes.length} aktif',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Aktif sporcu listesi
          Expanded(
            child: ListView.builder(
              itemCount: _activeAthletes.length,
              itemBuilder: (context, index) {
                final athlete = _activeAthletes[index];
                final warnings = _athleteWarnings[athlete.id] ?? 0;
                final isFailed = _athleteFailed[athlete.id] ?? false;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 2,
                  color: isFailed ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.cardBackgroundColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isFailed 
                          ? AppTheme.errorColor 
                          : (warnings > 0 ? AppTheme.warningColor : AppTheme.primaryColor),
                      child: Text(
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
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      'Uyarı: $warnings/2',
                      style: TextStyle(
                        color: warnings > 0 ? AppTheme.warningColor : AppTheme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isFailed)
                          IconButton(
                            onPressed: () => _markAthleteWarning(athlete.id),
                            icon: Icon(
                              Icons.warning,
                              color: AppTheme.warningColor,
                            ),
                            tooltip: 'Uyarı Ver',
                          ),
                        if (!isFailed)
                          IconButton(
                            onPressed: () => _markAthleteFailed(athlete.id),
                            icon: Icon(
                              Icons.cancel,
                              color: AppTheme.errorColor,
                            ),
                            tooltip: 'Başarısız İşaretle',
                          ),
                        if (isFailed)
                          Icon(
                            Icons.block,
                            color: AppTheme.errorColor,
                            size: 24,
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

  Widget _buildResultsSection() {
    return Expanded(
      child: Column(
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Test Sonuçları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Sonuç listesi
          Expanded(
            child: ListView.builder(
              itemCount: _selectedAthletes.length,
              itemBuilder: (context, index) {
                final athlete = _selectedAthletes[index];
                final level = _athleteLevels[athlete.id] ?? 1;
                final shuttle = _athleteShuttles[athlete.id] ?? 1;
                final failed = _athleteFailed[athlete.id] ?? false;
                final warnings = _athleteWarnings[athlete.id] ?? 0;
                
                final distanceCalc = _calculateDistance(failed?level-1:level, shuttle);
                final vo2Calc = _calculateVo2(distanceCalc);
                final detailNotes = '${failed ? 'Başarısız • ' : ''}Mesafe $distanceCalc m • VO2 ${vo2Calc.toStringAsFixed(1)}';

                return InkWell(
                  onTap: (){
                    showDialog(context: context,builder: (_)=>AlertDialog(
                      title: Text('${athlete.name} ${athlete.surname} Sonuç'),
                      content: Text(detailNotes),
                      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Kapat'))],
                    ));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: failed ? AppTheme.errorColor : AppTheme.successColor,
                            child: Icon(failed?Icons.cancel:Icons.check,color: AppTheme.whiteTextColor),
                          ),
                          const SizedBox(width:12),
                          Expanded(child:Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
                            Text('${athlete.name} ${athlete.surname}',style: TextStyle(fontWeight: FontWeight.bold,color: AppTheme.primaryTextColor,fontSize: 16)),
                            const SizedBox(height:4),
                            Text(failed? 'Seviye ${level-1} Mekik $shuttle • ${_calculateDistance(level-1,shuttle)} m':'Seviye $level Mekik $shuttle • ${_calculateDistance(level,shuttle)} m',style: TextStyle(color: AppTheme.secondaryTextColor,fontSize: 14)),
                            const SizedBox(height:2),
                            Text(_formatDateTime(DateTime.now()),style: TextStyle(color: AppTheme.secondaryTextColor,fontSize: 12)),
                          ])),
                          Column(children:[
                            Text('${_calculateDistance(failed?level-1:level,shuttle)}',style: TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:AppTheme.primaryColor)),
                            Text('Metre',style: TextStyle(fontSize:12,color:AppTheme.secondaryTextColor)),
                          ])
                        ],
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
} 