import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/services/pdf_export_service.dart';
import 'package:flutter/material.dart';

class TestResultAnalysisScreen extends StatefulWidget {
  final TestResultModel testResult;

  const TestResultAnalysisScreen({
    super.key,
    required this.testResult,
  });

  @override
  State<TestResultAnalysisScreen> createState() => _TestResultAnalysisScreenState();
}

class _TestResultAnalysisScreenState extends State<TestResultAnalysisScreen> {

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
    
    // Bölümleri ayır - yeni 3 bölümlü format için
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 4) { // 3 bölüm için (0. boş, 1-2-3. bölümler)
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
    } else {
      // Fallback: Tüm analizi tek bölüm olarak göster
      sections['degerlendirme'] = cleanAnalysis;
      sections['eksik_guclu'] = 'Bölüm ayrıştırılamadı';
      sections['genel_notlar'] = 'Bölüm ayrıştırılamadı';
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

  Widget _buildAnalysisCard(String sectionKey, String title, IconData icon, Color color) {
    final sections = _parseAnalysis(widget.testResult.aiAnalysis!);
    final content = sections[sectionKey] ?? 'İçerik bulunamadı';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                      color: const Color(0xFF1F2937),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Card content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
                  child: Text(
                  content,
                  style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 15,
                    color: const Color(0xFF374151),
                height: 1.6,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (widget.testResult.aiAnalysis == null || widget.testResult.aiAnalysis!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Analizi'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'AI Analizi Bulunamadı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu test sonucu için henüz AI analizi yapılmamış',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analizi'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                await PdfExportService.exportTestAnalysis(widget.testResult);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF başarıyla oluşturuldu ve açıldı!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF oluşturulurken hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // İçerik
          Column(
            children: [
              // Sporcu ve test bilgisi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sporcu bilgisi
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.testResult.athleteName[0]}${widget.testResult.athleteSurname[0]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.testResult.athleteName} ${widget.testResult.athleteSurname}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.testResult.testName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.testResult.result.toStringAsFixed(2)} ${widget.testResult.resultUnit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Test tarihi
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.testResult.testDate.day.toString().padLeft(2, '0')}.${widget.testResult.testDate.month.toString().padLeft(2, '0')}.${widget.testResult.testDate.year}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.testResult.testDate.hour.toString().padLeft(2, '0')}:${widget.testResult.testDate.minute.toString().padLeft(2, '0')}:${widget.testResult.testDate.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Not varsa göster
                    if (widget.testResult.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              color: Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.testResult.notes!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Analiz bölümleri
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Başlık
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 24,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Performans Analizi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                                    color: const Color(0xFF1F2937),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Detaylı değerlendirme ve öneriler',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 14,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Analiz bölümleri
                    _buildAnalysisCard(
                      'degerlendirme',
                      'Sonuç Değerlendirmesi',
                      Icons.insights,
                      const Color(0xFF10B981),
                    ),
                    
                    _buildAnalysisCard(
                      'eksik_guclu',
                      'Eksik Yönler',
                      Icons.trending_up,
                      const Color(0xFFF59E0B),
                    ),
                    
                    _buildAnalysisCard(
                      'genel_notlar',
                      'Egzersiz Önerisi',
                      Icons.fitness_center,
                      const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 