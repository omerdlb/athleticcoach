import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TestSessionAnalysisScreen extends StatefulWidget {
  final TestDefinitionModel selectedTest;
  final List<Map<String, dynamic>> results;

  const TestSessionAnalysisScreen({
    super.key,
    required this.selectedTest,
    required this.results,
  });

  @override
  State<TestSessionAnalysisScreen> createState() => _TestSessionAnalysisScreenState();
}

class _TestSessionAnalysisScreenState extends State<TestSessionAnalysisScreen> {
  final Map<String, String> _analysisResults = {};
  final Map<String, Map<String, String>> _analysisSections = {}; // Parçalanmış analizler
  final Map<String, bool> _isAnalyzing = {};
  final Map<String, bool> _isAnalysisExpanded = {};
  final Map<String, Map<String, bool>> _sectionExpanded = {}; // Her bölüm için ayrı durum
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final result in widget.results) {
      final athlete = result['athlete'] as AthleteModel;
      _isAnalyzing[athlete.id] = false;
      _analysisResults[athlete.id] = '';
      _analysisSections[athlete.id] = {};
      _isAnalysisExpanded[athlete.id] = false;
      _sectionExpanded[athlete.id] = {
        'degerlendirme': false,
        'eksik_guclu': false,
        'genel_notlar': false,
        'haftalik_program': false,
      };
    }
  }

  Future<void> _analyzeAthleteResult(AthleteModel athlete, double result, String? notes) async {
    setState(() {
      _isAnalyzing[athlete.id] = true;
    });

    try {
      final age = DateTime.now().year - athlete.birthDate.year;
      
      final prompt = '''
Bir sporcu için test sonucu analizi ve antrenman önerisi hazırla.

Sporcu Bilgileri (Bu bilgileri cevabında tekrar yazma, sadece analiz için kullan):
- Ad Soyad: ${athlete.name} ${athlete.surname}
- Yaş: ${DateTime.now().year - athlete.birthDate.year} yaşında
- Cinsiyet: ${athlete.gender}
- Branş: ${athlete.branch}
- Boy: ${athlete.height} cm
- Kilo: ${athlete.weight} kg

Test Bilgileri:
- Test: ${widget.selectedTest.name}
- Sonuç: $result ${widget.selectedTest.resultUnit}
- Antrenör notu: ${notes ?? 'Not girilmemiş'}

Lütfen şu başlıklar altında yanıtla (sporcu bilgilerini tekrar yazma):

1. SONUÇ DEĞERLENDİRMESİ:
Bu yaş ve cinsiyet için sonuç nasıl? Ortalama, iyi, çok iyi, zayıf?

2. EKSİK YÖNLER VE GÜÇLÜ YANLAR:
Sporcunun eksik yönleri ve güçlü yanları nelerdir?

3. GENEL NOTLAR:
Branşına göre bu kapasite önemli mi? Genel performans değerlendirmesi.

4. HAFTALIK PROGRAM:
Bu kapasiteyi geliştirmek için 4 haftalık örnek antrenman planı.

Türkçe olarak, kısa ve öz bir şekilde yanıtla. Her bölüm maksimum 100 kelime olsun. Gereksiz çizgiler, yıldızlar veya formatlamalar kullanma. Sporcu bilgilerini cevabında tekrar yazma.
''';

      final analysis = await GeminiService.generateContent(prompt);
      
      if (mounted && analysis != null) {
        setState(() {
          _analysisResults[athlete.id] = analysis;
          _analysisSections[athlete.id] = _parseAnalysis(analysis);
        });
        
        // Analiz tamamlandığında otomatik kaydet
        await _saveSingleResult(athlete, result, notes, analysis);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResults[athlete.id] = 'Analiz sırasında hata oluştu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing[athlete.id] = false;
        });
      }
    }
  }

  Future<void> _saveSingleResult(AthleteModel athlete, double result, String? notes, String analysis) async {
    try {
      final database = AthleteDatabase();
      final testDate = DateTime.now();

      final testResultModel = TestResultModel(
        id: _generateId(),
        testId: widget.selectedTest.id,
        testName: widget.selectedTest.name,
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testDate: testDate,
        result: result,
        resultUnit: widget.selectedTest.resultUnit,
        notes: notes?.isNotEmpty == true ? notes : null,
        aiAnalysis: analysis.isNotEmpty ? analysis : null,
      );

      await database.insertTestResult(testResultModel);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - Analiz kaydedildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${athlete.name} ${athlete.surname} - Kaydetme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _analyzeAllResults() async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (final result in widget.results) {
        final athlete = result['athlete'] as AthleteModel;
        final testResult = result['result'] as double;
        final notes = result['notes'] as String?;
        
        await _analyzeAthleteResult(athlete, testResult, notes);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Tüm analizler tamamlandığında ana sayfaya dön
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm analizler tamamlandı ve kaydedildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }



  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  Map<String, String> _parseAnalysis(String analysis) {
    final sections = <String, String>{};
    
    // Gereksiz çizgileri ve formatlamaları temizle
    String cleanAnalysis = analysis
        .replaceAll(RegExp(r'-{3,}'), '') // Üç veya daha fazla tire
        .replaceAll(RegExp(r'={3,}'), '') // Üç veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{3,}'), '') // Üç veya daha fazla yıldız
        .replaceAll(RegExp(r'_{3,}'), '') // Üç veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
    
    // Bölümleri ayır
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 5) {
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
      sections['haftalik_program'] = _cleanSection(parts[4]);
    } else {
      // Eğer bölümler ayrılamazsa, tüm metni genel notlara koy
      sections['genel_notlar'] = _cleanSection(cleanAnalysis);
    }
    
    return sections;
  }

  String _cleanSection(String section) {
    return section
        .replaceAll(RegExp(r'-{2,}'), '') // İki veya daha fazla tire
        .replaceAll(RegExp(r'={2,}'), '') // İki veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{2,}'), '') // İki veya daha fazla yıldız
        .replaceAll(RegExp(r'_{2,}'), '') // İki veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
  }

  Widget _buildAnalysisSection(String athleteId, String sectionKey, String title, IconData icon, Color color) {
    final sections = _analysisSections[athleteId];
    final content = sections?[sectionKey] ?? 'İçerik bulunamadı';
    final isExpanded = _sectionExpanded[athleteId]?[sectionKey] ?? false;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[athleteId]![sectionKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                content,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analizi'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Modern gradient header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedTest.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.results.length} sporcu',
                          style: const TextStyle(
                            color: Colors.white,
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
          
          // Modern analiz butonu
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _analyzeAllResults,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 24),
              label: Text(
                _isSaving ? 'Analizler Yapılıyor...' : 'Tümünü Analiz Et ve Kaydet',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
          
          // Tamamla butonu (analizler tamamlandığında görünür)
          if (_analysisResults.isNotEmpty && !_isSaving)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  'Tamamla - Ana Menüye Dön',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          
          // Analiz sonuçları
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.results.length,
              itemBuilder: (context, index) {
                final result = widget.results[index];
                final athlete = result['athlete'] as AthleteModel;
                final testResult = result['result'] as double;
                final notes = result['notes'] as String?;
                final isAnalyzing = _isAnalyzing[athlete.id] ?? false;
                final analysis = _analysisResults[athlete.id] ?? '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sporcu bilgileri
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  '${athlete.name[0]}${athlete.surname[0]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          athlete.branch,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${DateTime.now().year - athlete.birthDate.year} yaş',
                                          style: const TextStyle(
                                            color: Color(0xFF1E40AF),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          athlete.gender,
                                          style: const TextStyle(
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$testResult ${widget.selectedTest.resultUnit}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Not varsa göster
                        if (notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Color(0xFF92400E),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notes!,
                                    style: const TextStyle(
                                      color: Color(0xFF92400E),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Analiz bölümü
                        if (isAnalyzing)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'AI analizi yapılıyor...',
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (analysis.isNotEmpty)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isAnalysisExpanded[athlete.id] = !(_isAnalysisExpanded[athlete.id] ?? false);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            size: 20,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'AI Analizi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E40AF),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          _isAnalysisExpanded[athlete.id] == true
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF3B82F6),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isAnalysisExpanded[athlete.id] == true)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        // Sonuç Değerlendirmesi
                                        _buildAnalysisSection(
                                          athlete.id,
                                          'degerlendirme',
                                          'Sonuç Değerlendirmesi',
                                          Icons.analytics,
                                          const Color(0xFF10B981),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Eksik Yönler ve Güçlü Yanlar
                                        _buildAnalysisSection(
                                          athlete.id,
                                          'eksik_guclu',
                                          'Eksik Yönler ve Güçlü Yanlar',
                                          Icons.trending_up,
                                          const Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Genel Notlar
                                        _buildAnalysisSection(
                                          athlete.id,
                                          'genel_notlar',
                                          'Genel Notlar',
                                          Icons.note,
                                          const Color(0xFF8B5CF6),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Haftalık Program
                                        _buildAnalysisSection(
                                          athlete.id,
                                          'haftalik_program',
                                          'Haftalık Program',
                                          Icons.calendar_today,
                                          const Color(0xFFEF4444),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6B7280).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _analyzeAthleteResult(athlete, testResult, notes),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text(
                                'Bu Sporcuyu Analiz Et',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
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
} 