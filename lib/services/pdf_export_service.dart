import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfExportService {
  // Tema renklerini PDF renklerine çevir
  static PdfColor _getPdfColor(Color color) {
    return PdfColor.fromInt(color.value);
  }

  static Future<void> exportTestAnalysis(TestResultModel testResult) async {
    try {
      // Font yükle
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      final bebasFont = pw.Font.ttf(fontData);
      
      // PDF oluştur
      final pdf = pw.Document();
      
      // Tek sayfa PDF oluştur
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildSinglePageAnalysis(testResult, bebasFont),
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

  static Future<void> exportAthleteProfile(AthleteModel athlete, List<TestResultModel> testResults) async {
    try {
      // Font yükle
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      final bebasFont = pw.Font.ttf(fontData);
      
      // PDF oluştur
      final pdf = pw.Document();
      
      // PDF sayfalarını oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Profil başlık sayfası
            _buildProfileHeaderPage(athlete, bebasFont),
            // Test sonuçları sayfası
            _buildTestResultsPage(athlete, testResults, bebasFont),
            // AI analizleri sayfası
            _buildProfileAnalysisPage(athlete, testResults, bebasFont),
          ],
        ),
      );
      
      // Dosyayı kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/athlete_profile_${athlete.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Dosyayı aç
      await OpenFile.open(file.path);
      
    } catch (e) {
      throw Exception('PDF oluşturulurken hata: $e');
    }
  }
  
  static pw.Widget _buildSinglePageAnalysis(TestResultModel testResult, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Ana başlık - Tema renkleri kullan
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _getPdfColor(AppTheme.primaryColor),
                  _getPdfColor(AppTheme.accentColor),
                ],
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
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'AI Performans Analizi Raporu',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                  ),
                  child: pw.Text(
                    'Yapay Zeka Destekli Analiz',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _getPdfColor(AppTheme.primaryColor),
                      font: bebasFont,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 15),
          
          // Sporcu bilgileri kartı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getPdfColor(AppTheme.primaryColor),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'Sporcu Bilgileri',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      font: bebasFont,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildInfoRow('Ad Soyad', '${testResult.athleteName} ${testResult.athleteSurname}', bebasFont),
                _buildInfoRow('Test Adı', testResult.testName, bebasFont),
                _buildInfoRow('Test Sonucu', '${testResult.result.toStringAsFixed(2)} ${testResult.resultUnit}', bebasFont),
                _buildInfoRow('Test Tarihi', '${testResult.testDate.day.toString().padLeft(2, '0')}.${testResult.testDate.month.toString().padLeft(2, '0')}.${testResult.testDate.year}', bebasFont),
                if (testResult.notes?.isNotEmpty == true) 
                  _buildInfoRow('Notlar', testResult.notes!, bebasFont),
              ],
            ),
          ),
          
          pw.SizedBox(height: 15),
          
          // AI Analiz - Başlık olmadan direkt içerik
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: _getPdfColor(AppTheme.primaryColor), width: 2),
            ),
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              child: pw.Text(
                testResult.aiAnalysis ?? 'Analiz bulunamadı.',
                style: pw.TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: _getPdfColor(AppTheme.primaryTextColor),
                  font: bebasFont,
                ),
              ),
            ),
          ),
          
          pw.SizedBox(height: 15),
          
          // Alt bilgi
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _getPdfColor(AppTheme.secondaryTextColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Bu rapor Athletic Coach uygulaması tarafından yapay zeka ile hazırlanmıştır.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Rapor Tarihi: ${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                  style: pw.TextStyle(
                    fontSize: 9,
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

  static pw.Widget _buildProfileHeaderPage(AthleteModel athlete, pw.Font bebasFont) {
    final age = DateTime.now().year - athlete.birthDate.year;
    
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Ana başlık - Tema renkleri kullan
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _getPdfColor(AppTheme.primaryColor),
                  _getPdfColor(AppTheme.accentColor),
                ],
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
                  'Sporcu Profil Raporu',
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
                    'Kapsamlı Performans Analizi',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: _getPdfColor(AppTheme.primaryColor),
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
              border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _getPdfColor(AppTheme.primaryColor),
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
                _buildInfoRow('Ad Soyad', '${athlete.name} ${athlete.surname}', bebasFont),
                _buildInfoRow('Yaş', '$age yaş', bebasFont),
                _buildInfoRow('Cinsiyet', athlete.gender, bebasFont),
                _buildInfoRow('Branş', athlete.branch, bebasFont),
                _buildInfoRow('Boy', '${athlete.height} cm', bebasFont),
                _buildInfoRow('Kilo', '${athlete.weight} kg', bebasFont),
                _buildInfoRow('Doğum Tarihi', '${athlete.birthDate.day.toString().padLeft(2, '0')}.${athlete.birthDate.month.toString().padLeft(2, '0')}.${athlete.birthDate.year}', bebasFont),
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
                color: _getPdfColor(AppTheme.secondaryTextColor),
                font: bebasFont,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: _getPdfColor(AppTheme.primaryTextColor),
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
                colors: [
                  _getPdfColor(AppTheme.secondaryColor),
                  _getPdfColor(AppTheme.accentColor),
                ],
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
          
          // Tek parça analiz
          _buildFullAnalysisSection(
            testResult.aiAnalysis ?? 'Analiz bulunamadı.',
            _getPdfColor(AppTheme.primaryColor),
            bebasFont,
          ),
          
          pw.SizedBox(height: 25),
          
          // Alt bilgi
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: _getPdfColor(AppTheme.secondaryTextColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor)),
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

  static pw.Widget _buildTestResultsPage(AthleteModel athlete, List<TestResultModel> testResults, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Test sonuçları başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _getPdfColor(AppTheme.primaryColor),
                  _getPdfColor(AppTheme.accentColor),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Text(
              'Test Sonuçları Geçmişi',
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
          
          // Test sonuçları tablosu
          if (testResults.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor), width: 1),
              ),
              child: pw.Column(
                children: [
                  // Tablo başlığı
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: _getPdfColor(AppTheme.primaryColor),
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(11),
                        topRight: pw.Radius.circular(11),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Test Adı',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: bebasFont,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Sonuç',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: bebasFont,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Tarih',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: bebasFont,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tablo satırları
                  ...testResults.map((result) => pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: _getPdfColor(AppTheme.borderColor),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            result.testName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _getPdfColor(AppTheme.primaryTextColor),
                              font: bebasFont,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _getPdfColor(AppTheme.primaryColor),
                              fontWeight: pw.FontWeight.bold,
                              font: bebasFont,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${result.testDate.day.toString().padLeft(2, '0')}.${result.testDate.month.toString().padLeft(2, '0')}.${result.testDate.year}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _getPdfColor(AppTheme.secondaryTextColor),
                              font: bebasFont,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ] else ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor), width: 1),
              ),
              child: pw.Text(
                'Henüz test sonucu bulunmamaktadır.',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: _getPdfColor(AppTheme.secondaryTextColor),
                  font: bebasFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildProfileAnalysisPage(AthleteModel athlete, List<TestResultModel> testResults, pw.Font bebasFont) {
    // AI analizi olan test sonuçlarını filtrele
    final analyzedResults = testResults.where((result) => 
      result.aiAnalysis != null && result.aiAnalysis!.isNotEmpty
    ).toList();

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // AI Analizleri başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _getPdfColor(AppTheme.secondaryColor),
                  _getPdfColor(AppTheme.accentColor),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Text(
              'AI Performans Analizleri',
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
          
          if (analyzedResults.isNotEmpty) ...[
            ...analyzedResults.map((result) {
              final analysisSections = _parseAnalysis(result.aiAnalysis!);
              return pw.Column(
                children: [
                  _buildTestAnalysisSection(result, analysisSections, bebasFont),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ] else ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: _getPdfColor(AppTheme.borderColor), width: 1),
              ),
              child: pw.Text(
                'Henüz AI analizi yapılmamış test sonucu bulunmamaktadır.',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: _getPdfColor(AppTheme.secondaryTextColor),
                  font: bebasFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildTestAnalysisSection(TestResultModel result, Map<String, String> sections, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: _getPdfColor(AppTheme.primaryColor), width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Test başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: _getPdfColor(AppTheme.primaryColor),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  result.testName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${result.result.toStringAsFixed(2)} ${result.resultUnit} - ${result.testDate.day.toString().padLeft(2, '0')}.${result.testDate.month.toString().padLeft(2, '0')}.${result.testDate.year}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
              ],
            ),
          ),
          
          // Tek parça analiz
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(
              result.aiAnalysis ?? 'Analiz bulunamadı.',
              style: pw.TextStyle(
                fontSize: 11,
                height: 1.5,
                color: _getPdfColor(AppTheme.primaryTextColor),
                font: bebasFont,
              ),
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
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bölüm başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: bebasFont,
              ),
            ),
          ),
          
          // İçerik
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              content,
              style: pw.TextStyle(
                fontSize: 10,
                height: 1.4,
                color: _getPdfColor(AppTheme.primaryTextColor),
                font: bebasFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFullAnalysisSection(String analysis, PdfColor color, pw.Font bebasFont) {
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
          // Analiz başlığı
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
              'AI Analiz Raporu',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: bebasFont,
              ),
            ),
          ),
          
          // Analiz içeriği
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(
              analysis,
              style: pw.TextStyle(
                fontSize: 12,
                height: 1.6,
                color: _getPdfColor(AppTheme.primaryTextColor),
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