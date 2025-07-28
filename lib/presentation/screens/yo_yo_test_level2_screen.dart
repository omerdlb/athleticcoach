import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class YoYoTestLevel2Screen extends StatefulWidget {
  const YoYoTestLevel2Screen({super.key});

  @override
  State<YoYoTestLevel2Screen> createState() => _YoYoTestLevel2ScreenState();
}

class _YoYoTestLevel2ScreenState extends State<YoYoTestLevel2Screen> {
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
  
  // Yo-Yo IR2 seviye verileri (saniye cinsinden bip aralıkları)
  // Level 2 daha hızlı başlar ve daha hızlı ilerler
  final Map<int, double> _levelIntervals = {
    1: 6.0, 2: 6.0, 3: 6.0, 4: 6.0, 5: 6.0, 6: 6.0, 7: 6.0, 8: 6.0,
    9: 5.5, 10: 5.5, 11: 5.5, 12: 5.5, 13: 5.5, 14: 5.5, 15: 5.5, 16: 5.5,
    17: 5.0, 18: 5.0, 19: 5.0, 20: 5.0, 21: 5.0, 22: 5.0, 23: 5.0, 24: 5.0,
    25: 4.5, 26: 4.5, 27: 4.5, 28: 4.5, 29: 4.5, 30: 4.5, 31: 4.5, 32: 4.5,
    33: 4.0, 34: 4.0, 35: 4.0, 36: 4.0, 37: 4.0, 38: 4.0, 39: 4.0, 40: 4.0,
    41: 3.5, 42: 3.5, 43: 3.5, 44: 3.5, 45: 3.5, 46: 3.5, 47: 3.5, 48: 3.5,
    49: 3.0, 50: 3.0, 51: 3.0, 52: 3.0, 53: 3.0, 54: 3.0, 55: 3.0, 56: 3.0,
    57: 2.5, 58: 2.5, 59: 2.5, 60: 2.5, 61: 2.5, 62: 2.5, 63: 2.5, 64: 2.5,
    65: 2.0, 66: 2.0, 67: 2.0, 68: 2.0, 69: 2.0, 70: 2.0, 71: 2.0, 72: 2.0,
    73: 1.5, 74: 1.5, 75: 1.5, 76: 1.5, 77: 1.5, 78: 1.5, 79: 1.5, 80: 1.5,
    81: 1.0, 82: 1.0, 83: 1.0, 84: 1.0, 85: 1.0, 86: 1.0, 87: 1.0, 88: 1.0,
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
      print('Yo-Yo Level 2 sesleri yüklendi');
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
      _skipNextShuttleAdvance = false;
      _pendingLevelUp = false;
      
      // Aktif sporcuları ayarla
      _activeAthletes = List.from(_selectedAthletes);
      
      // Sporcu durumlarını sıfırla
      for (final athlete in _activeAthletes) {
        _athleteLevels[athlete.id] = 1;
        _athleteShuttles[athlete.id] = 1;
        _athleteWarnings[athlete.id] = 0;
        _athleteFailed[athlete.id] = false;
      }
    });

    _startBeepSequence();
    _startTestTimer();
  }

  void _pauseTest() {
    setState(() {
      _isTestPaused = true;
    });
    _testTimer?.cancel();
    _beepTimer?.cancel();
    _restTimer?.cancel();
  }

  void _resumeTest() {
    setState(() {
      _isTestPaused = false;
    });
    _startBeepSequence();
    _startTestTimer();
  }

  void _stopTest() {
    _testTimer?.cancel();
    _beepTimer?.cancel();
    _restTimer?.cancel();
    
    setState(() {
      _isTestRunning = false;
      _isTestPaused = false;
    });
    
    _saveTestResults();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTestPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _startBeepSequence() {
    _beepTimer?.cancel();

    // İlk bip hemen
    if (!_isRestPeriod && !_isTestPaused) {
      _playBeepSound();
    }

    _scheduleNextBeep();
  }

  void _scheduleNextBeep() {
    if (!_isTestRunning || _isTestPaused || _isRestPeriod) return;

    final interval = _levelIntervals[_currentLevel] ?? 6.0;
    _beepTimer = Timer(Duration(milliseconds: (interval * 1000).round()), () {
      if (_isTestRunning && !_isTestPaused && !_isRestPeriod) {
        _playBeepSound();
        if (_skipNextShuttleAdvance) {
          _skipNextShuttleAdvance = false;
        } else {
          _advanceShuttle();
        }
        _scheduleNextBeep();
      }
    });
  }

  void _playBeepSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/yoyobeepsound.mp3'));
    } catch (e) {
      print('Bip sesi çalınamadı: $e');
    }
  }

  void _playRestSound() async {
    try {
      await _restAudioPlayer.play(AssetSource('sounds/yoyorestsound.mp3'));
    } catch (e) {
      print('Dinlenme sesi çalınamadı: $e');
    }
  }

  void _advanceShuttle() {
    // Dinlenme sonrasındaki ilk bipte mekik artırma atlandı mı?
    if (_skipNextShuttleAdvance) {
      _skipNextShuttleAdvance = false;
      return;
    }

    setState(() {
      // Bir shuttle (20 m) tamamlandı
      _currentShuttle++;

      // Çift shuttle (gidiş-geliş = 40 m) tamamlandıysa dinlenme
      if (_currentShuttle % 2 == 0) {
        // Seviye tamamlandı mı kontrolü (8 shuttle = 4 gidiş-geliş)
        if (_currentShuttle == _totalShuttles) {
          _pendingLevelUp = true; // Dinlenme bitince seviye artışı yapılacak
        }
        _startRestPeriod();
        return; // Dinlenme başlatıldı, fonksiyonu terk et
      }

      // Çift değilse (dinlenme yok) ama seviye bitmiş olabilir
      if (_currentShuttle > _totalShuttles) {
        // Seviye atla
        _currentLevel++;
        _currentShuttle = 1;
        for (final athlete in _activeAthletes) {
          _athleteLevels[athlete.id] = _currentLevel;
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
      } else {
        // Sadece mekik bilgisini güncelle
        for (final athlete in _activeAthletes) {
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
      }
    });
  }

  void _startRestPeriod() {
    setState(() {
      _isRestPeriod = true;
      _restCountdown = 10; // 10 saniye aktif dinlenme
      _skipNextShuttleAdvance = true; // Dinlenme sonrası ilk bipte mekik artırılmasın
    });

    _playRestSound();

    _restTimer?.cancel();
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
        // Seviye artır
        _currentLevel++;
        _currentShuttle = 1;
        for (final athlete in _activeAthletes) {
          _athleteLevels[athlete.id] = _currentLevel;
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
        _pendingLevelUp = false;
      } else {
        // Dinlenme sonrası tek shuttle (gidiş) ile devam edecek
        _currentShuttle++;
        for (final athlete in _activeAthletes) {
          _athleteShuttles[athlete.id] = _currentShuttle;
        }
      }
    });

    // Yeni bip zamanlayıcısını başlat
    _beepTimer?.cancel();
    _startBeepSequence();
  }

  void _markAthleteWarning(String athleteId) {
    setState(() {
      _athleteWarnings[athleteId] = (_athleteWarnings[athleteId] ?? 0) + 1;
      
      // 2 uyarı alan sporcu başarısız
      if (_athleteWarnings[athleteId]! >= 2) {
        _athleteFailed[athleteId] = true;
        _activeAthletes.removeWhere((athlete) => athlete.id == athleteId);
      }
    });
  }

  void _markAthleteFailed(String athleteId) {
    setState(() {
      _athleteFailed[athleteId] = true;
      _activeAthletes.removeWhere((athlete) => athlete.id == athleteId);
    });
  }

  void _toggleAthleteSelection(AthleteModel athlete) {
    setState(() {
      if (_selectedAthletes.any((a) => a.id == athlete.id)) {
        _selectedAthletes.removeWhere((a) => a.id == athlete.id);
      } else {
        _selectedAthletes.add(athlete);
      }
    });
  }

  Future<void> _saveTestResults() async {
    final testId = '${DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS').format(DateTime.now())}_${DateTime.now().millisecondsSinceEpoch}';
    final sessionId = '${testId}_0';
    
    for (final athlete in _selectedAthletes) {
      final level = _athleteLevels[athlete.id] ?? 1;
      final shuttle = _athleteShuttles[athlete.id] ?? 1;
      final warnings = _athleteWarnings[athlete.id] ?? 0;
      final failed = _athleteFailed[athlete.id] ?? false;
      
      // Toplam mesafeyi hesapla (Level 2 için)
      int totalDistance = 0;
      for (int l = 1; l < level; l++) {
        totalDistance += 8 * 40; // Her seviyede 8 mekik, her mekik 40m (20m gidiş + 20m geliş)
      }
      totalDistance += (shuttle - 1) * 40; // Mevcut seviyedeki mekikler
      
      final result = TestResultModel(
        id: '${testId}_${athlete.id}',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testName: 'Yo-Yo Intermittent Recovery Test Level 2',
        testId: testId,
        sessionId: sessionId,
        result: totalDistance.toDouble(),
        resultUnit: 'm',
        testDate: DateTime.now(),
        notes: 'Seviye: $level, Mekik: $shuttle, Uyarı: $warnings, Başarısız: ${failed ? "Evet" : "Hayır"}',
      );
      
      await _database.insertTestResult(result);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test sonuçları kaydedildi'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yo-Yo IR2 Test'),
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
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        '${_athleteLevels[athlete.id] ?? 1}',
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
                      style: TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _markAthleteWarning(athlete.id),
                          icon: Icon(Icons.warning, color: Colors.orange),
                          tooltip: 'Uyarı Ver',
                        ),
                        IconButton(
                          onPressed: () => _markAthleteFailed(athlete.id),
                          icon: Icon(Icons.close, color: Colors.red),
                          tooltip: 'Başarısız',
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Test Tamamlandı!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuçlar kaydedildi. Test sonuçları sayfasından görüntüleyebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  
 } 