import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfExportService {
  static Future<void> exportTestAnalysis(TestResultModel testResult) async {
    try {
      // Font yükle
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      final bebasFont = pw.Font.ttf(fontData);
      
      // PDF oluştur
      final pdf = pw.Document();
      
      // Analizi parçala
      final analysisSections = _parseAnalysis(testResult.aiAnalysis ?? '');
      
      // PDF sayfalarını oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Başlık sayfası
            _buildHeaderPage(testResult, bebasFont),
            // Analiz sayfası
            _buildAnalysisPage(testResult, analysisSections, bebasFont),
          ],
        ),
      );
      
      // Dosyayı kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/test_analysis_${testResult.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Dosyayı aç
      await OpenFile.open(file.path);
      
    } catch (e) {
      throw Exception('PDF oluşturulurken hata: $e');
    }
  }
  
  static pw.Widget _buildHeaderPage(TestResultModel testResult, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Ana başlık
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue, PdfColors.indigo],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ATHLETIC COACH',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'AI Performans Analizi Raporu',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                  ),
                  child: pw.Text(
                    'Yapay Zeka Destekli Analiz',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.blue,
                      font: bebasFont,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 25),
          
          // Sporcu bilgileri kartı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: PdfColors.grey, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    'Sporcu Bilgileri',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      font: bebasFont,
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),
                _buildInfoRow('Ad Soyad', '${testResult.athleteName} ${testResult.athleteSurname}', bebasFont),
                _buildInfoRow('Test Adı', testResult.testName, bebasFont),
                _buildInfoRow('Test Sonucu', '${testResult.result.toStringAsFixed(2)} ${testResult.resultUnit}', bebasFont),
                _buildInfoRow('Test Tarihi', '${testResult.testDate.day.toString().padLeft(2, '0')}.${testResult.testDate.month.toString().padLeft(2, '0')}.${testResult.testDate.year}', bebasFont),
                if (testResult.notes?.isNotEmpty == true) 
                  _buildInfoRow('Notlar', testResult.notes!, bebasFont),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value, pw.Font bebasFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.grey,
                font: bebasFont,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
                font: bebasFont,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAnalysisPage(TestResultModel testResult, Map<String, String> sections, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Analiz başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.green, PdfColors.teal],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Text(
              'AI Performans Analizi',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: bebasFont,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Analiz bölümleri
          _buildAnalysisSection(
            'Sonuç Değerlendirmesi',
            sections['degerlendirme'] ?? 'Değerlendirme bulunamadı.',
            PdfColors.blue,
            bebasFont,
          ),
          
          pw.SizedBox(height: 15),
          
          _buildAnalysisSection(
            'Eksik Yönler',
            sections['eksik_guclu'] ?? 'Eksik yönler bulunamadı.',
            PdfColors.orange,
            bebasFont,
          ),
          
          pw.SizedBox(height: 15),
          
          _buildAnalysisSection(
            'Egzersiz Önerisi',
            sections['genel_notlar'] ?? 'Egzersiz önerisi bulunamadı.',
            PdfColors.purple,
            bebasFont,
          ),
          
          pw.SizedBox(height: 25),
          
          // Alt bilgi
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Bu rapor Athletic Coach uygulaması tarafından',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'yapay zeka ile hazırlanmıştır.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Rapor Tarihi: ${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAnalysisSection(String title, String content, PdfColor color, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bölüm başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: bebasFont,
              ),
            ),
          ),
          
          // İçerik
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            child: pw.Text(
              content,
              style: pw.TextStyle(
                fontSize: 12,
                height: 1.6,
                color: PdfColors.black,
                font: bebasFont,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static Map<String, String> _parseAnalysis(String analysis) {
    final sections = <String, String>{};
    
    // Gereksiz çizgileri ve formatlamaları temizle
    String cleanAnalysis = analysis
        .replaceAll(RegExp(r'-{3,}'), '')
        .replaceAll(RegExp(r'={3,}'), '')
        .replaceAll(RegExp(r'\*{3,}'), '')
        .replaceAll(RegExp(r'_{3,}'), '')
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '')
        .trim();
    
    // Yeni 3 bölümlü format için ayırma
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 4) {
      // Yeni format: 3 bölüm
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
    } else {
      // Eğer bölümler ayrılamazsa, tüm metni genel notlara koy
      sections['genel_notlar'] = _cleanSection(cleanAnalysis);
    }
    
    return sections;
  }
  
  static String _cleanSection(String section) {
    return section
        .replaceAll(RegExp(r'-{2,}'), '')
        .replaceAll(RegExp(r'={2,}'), '')
        .replaceAll(RegExp(r'\*{2,}'), '')
        .replaceAll(RegExp(r'_{2,}'), '')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '')
        .trim();
  }
} 