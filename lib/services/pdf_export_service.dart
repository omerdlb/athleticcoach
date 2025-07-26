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
          margin: const pw.EdgeInsets.all(25),
          build: (context) => [
            // Başlık sayfası
            _buildHeaderPage(testResult, bebasFont, analysisSections),
            // Analiz sayfaları
            ..._buildAnalysisPages(testResult, analysisSections, bebasFont),
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
  
  static pw.Widget _buildHeaderPage(TestResultModel testResult, pw.Font bebasFont, Map<String, String> analysisSections) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Ana başlık
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ATHLETIC COACH',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Test Sonucu Analizi',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Sporcu bilgileri
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Sporcu Bilgileri',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text('Ad Soyad: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: bebasFont)),
                    pw.Text('${testResult.athleteName} ${testResult.athleteSurname}', style: pw.TextStyle(font: bebasFont)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Text('Test: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: bebasFont)),
                    pw.Text(testResult.testName, style: pw.TextStyle(font: bebasFont)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Text('Sonuç: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: bebasFont)),
                    pw.Text('${testResult.result.toStringAsFixed(2)} ${testResult.resultUnit}', style: pw.TextStyle(font: bebasFont)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Text('Tarih: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: bebasFont)),
                    pw.Text('${testResult.testDate.day.toString().padLeft(2, '0')}.${testResult.testDate.month.toString().padLeft(2, '0')}.${testResult.testDate.year}', style: pw.TextStyle(font: bebasFont)),
                  ],
                ),
                if (testResult.notes?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Notlar: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: bebasFont)),
                      pw.Expanded(
                        child: pw.Text(testResult.notes!, style: pw.TextStyle(font: bebasFont)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // AI Performans Analizi ve Sonuç Değerlendirmesi (aynı kart içinde)
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // AI Analizi başlığı
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Text(
                  'AI Performans Analizi',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      font: bebasFont,
                    ),
                  ),
                ),
                
                // Sonuç Değerlendirmesi içeriği
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Sonuç Değerlendirmesi',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                          font: bebasFont,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        analysisSections['degerlendirme'] ?? 'Değerlendirme bulunamadı.',
                        style: pw.TextStyle(
                          fontSize: 12,
                          height: 1.5,
                    font: bebasFont,
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
    );
  }
  
  static List<pw.Widget> _buildAnalysisPages(TestResultModel testResult, Map<String, String> sections, pw.Font bebasFont) {
    final pages = <pw.Widget>[];
    
    // Bölüm başlıkları (değerlendirme hariç, çünkü başlık sayfasında)
    final sectionTitles = {
      'eksik_guclu': 'Eksik Yönler ve Güçlü Yanlar',
      'genel_notlar': 'Genel Notlar',
      'haftalik_program': 'Haftalık Program',
      'beslenme_dinlenme': 'Beslenme ve Dinlenme',
      'uzun_vadeli': 'Uzun Vadeli Gelişim',
    };
    
    final sectionColors = {
      'eksik_guclu': PdfColors.orange,
      'genel_notlar': PdfColors.purple,
      'haftalik_program': PdfColors.red,
      'beslenme_dinlenme': PdfColors.green,
      'uzun_vadeli': PdfColors.indigo,
    };
    
    // Bölümleri 2'li gruplar halinde düzenle
    final sectionEntries = sectionTitles.entries.toList();
    for (int i = 0; i < sectionEntries.length; i += 2) {
      final widgets = <pw.Widget>[];
      
      // İlk bölüm
      final firstEntry = sectionEntries[i];
      widgets.add(_buildSectionCard(
        firstEntry.key,
        firstEntry.value,
        sections[firstEntry.key] ?? 'Bu bölüm için içerik bulunamadı.',
        sectionColors[firstEntry.key] ?? PdfColors.blue,
        bebasFont,
      ));
      
      // İkinci bölüm (varsa)
      if (i + 1 < sectionEntries.length) {
        final secondEntry = sectionEntries[i + 1];
        widgets.add(_buildSectionCard(
          secondEntry.key,
          secondEntry.value,
          sections[secondEntry.key] ?? 'Bu bölüm için içerik bulunamadı.',
          sectionColors[secondEntry.key] ?? PdfColors.blue,
          bebasFont,
        ));
      }
      
      // Yan yana yerleştir
      pages.add(
        pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: widgets.map((widget) => 
            pw.Expanded(child: widget)
          ).toList(),
        ),
      );
      
      // Sayfalar arası boşluk
      if (i + 2 < sectionEntries.length) {
        pages.add(pw.SizedBox(height: 20));
      }
    }
    
    // Son sayfaya AI bilgisi ekle
    pages.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
        child: pw.Text(
          'Bu rapor Athletic Coach uygulaması tarafından yapay zeka ile hazırlanmıştır.',
          style: pw.TextStyle(
            fontSize: 12,
                        color: PdfColors.white,
            font: bebasFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
    
    return pages;
  }
  
  static pw.Widget _buildSectionCard(String sectionKey, String title, String content, PdfColor color, pw.Font bebasFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bölüm başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
                      title,
                      style: pw.TextStyle(
                fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                        font: bebasFont,
                      ),
                ),
              ),
              
          pw.SizedBox(height: 10),
              
              // İçerik
              pw.Container(
                width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  content,
                  style: pw.TextStyle(
                fontSize: 11,
                height: 1.4,
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
        .replaceAll(RegExp(r'-{3,}'), '') // Üç veya daha fazla tire
        .replaceAll(RegExp(r'={3,}'), '') // Üç veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{3,}'), '') // Üç veya daha fazla yıldız
        .replaceAll(RegExp(r'_{3,}'), '') // Üç veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
    
    // Bölümleri ayır - yeni detaylı format için
    final parts = cleanAnalysis.split(RegExp(r'\d+\.\s*'));
    
    if (parts.length >= 7) {
      // Yeni detaylı format: 6 bölüm
      sections['degerlendirme'] = _cleanSection(parts[1]);
      sections['eksik_guclu'] = _cleanSection(parts[2]);
      sections['genel_notlar'] = _cleanSection(parts[3]);
      sections['haftalik_program'] = _cleanSection(parts[4]);
      sections['beslenme_dinlenme'] = _cleanSection(parts[5]);
      sections['uzun_vadeli'] = _cleanSection(parts[6]);
    } else if (parts.length >= 5) {
      // Eski format: 4 bölüm
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
  
  static String _cleanSection(String section) {
    return section
        .replaceAll(RegExp(r'-{2,}'), '') // İki veya daha fazla tire
        .replaceAll(RegExp(r'={2,}'), '') // İki veya daha fazla eşittir
        .replaceAll(RegExp(r'\*{2,}'), '') // İki veya daha fazla yıldız
        .replaceAll(RegExp(r'_{2,}'), '') // İki veya daha fazla alt çizgi
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Fazla boş satırları
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Satır başı/sonu boşlukları
        .trim();
  }
} 