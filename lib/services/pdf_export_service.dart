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

  static Future<void> exportAthleteComparison({
    required AthleteModel athlete1,
    required AthleteModel athlete2,
    required List<TestResultModel> athlete1Results,
    required List<TestResultModel> athlete2Results,
    required String comparisonAnalysis,
  }) async {
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
          build: (context) => _buildComparisonSinglePage(
            athlete1,
            athlete2,
            athlete1Results,
            athlete2Results,
            comparisonAnalysis,
            bebasFont,
          ),
        ),
      );
      
      // Dosyayı kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/athlete_comparison_${athlete1.id}_${athlete2.id}.pdf');
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

  static pw.Widget _buildComparisonHeaderPage(AthleteModel athlete1, AthleteModel athlete2, pw.Font bebasFont) {
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
                  'Sporcu Karşılaştırma Raporu',
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
                    'Kapsamlı Karşılaştırma Analizi',
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
          
          // Karşılaştırma bilgileri kartı
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
                    'Karşılaştırma Bilgileri',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      font: bebasFont,
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),
                _buildInfoRow('Sporcu 1', '${athlete1.name} ${athlete1.surname}', bebasFont),
                _buildInfoRow('Sporcu 2', '${athlete2.name} ${athlete2.surname}', bebasFont),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonAthletesPage(AthleteModel athlete1, AthleteModel athlete2, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sporcu bilgileri başlığı
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
              'Sporcu Bilgileri',
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
          
          // Sporcu bilgileri tablosu
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
                          'Özellik',
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
                          'Sporcu 1',
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
                          'Sporcu 2',
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
                pw.Container(
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
                          'Ad Soyad',
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
                          '${athlete1.name} ${athlete1.surname}',
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
                          '${athlete2.name} ${athlete2.surname}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Yaş',
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
                           '${DateTime.now().year - athlete1.birthDate.year} yaş',
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
                          '${DateTime.now().year - athlete2.birthDate.year} yaş',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Cinsiyet',
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
                          athlete1.gender,
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
                          athlete2.gender,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Branş',
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
                          athlete1.branch,
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
                          athlete2.branch,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Boy',
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
                          '${athlete1.height} cm',
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
                          '${athlete2.height} cm',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Kilo',
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
                          '${athlete1.weight} kg',
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
                          '${athlete2.weight} kg',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
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
                          'Doğum Tarihi',
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
                          '${athlete1.birthDate.day.toString().padLeft(2, '0')}.${athlete1.birthDate.month.toString().padLeft(2, '0')}.${athlete1.birthDate.year}',
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
                          '${athlete2.birthDate.day.toString().padLeft(2, '0')}.${athlete2.birthDate.month.toString().padLeft(2, '0')}.${athlete2.birthDate.year}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _getPdfColor(AppTheme.primaryTextColor),
                            font: bebasFont,
                          ),
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

  static pw.Widget _buildComparisonResultsPage(AthleteModel athlete1, AthleteModel athlete2, List<TestResultModel> athlete1Results, List<TestResultModel> athlete2Results, pw.Font bebasFont) {
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
              'Test Sonuçları Karşılaştırma',
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
          if (athlete1Results.isNotEmpty || athlete2Results.isNotEmpty) ...[
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
                            'Sporcu 1',
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
                            'Sporcu 2',
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
                  ..._mergeAndSortResults(athlete1Results, athlete2Results).map((result) => pw.Container(
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
                              color: _getPdfColor(AppTheme.primaryTextColor),
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

  static pw.Widget _buildComparisonAnalysisPage(String comparisonAnalysis, pw.Font bebasFont) {
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
              'AI Karşılaştırma Analizi',
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
            comparisonAnalysis,
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

  static List<TestResultModel> _mergeAndSortResults(List<TestResultModel> athlete1Results, List<TestResultModel> athlete2Results) {
    final mergedResults = <TestResultModel>[];
    final Map<String, TestResultModel> athlete1Map = {};
    final Map<String, TestResultModel> athlete2Map = {};

    // Sadece aynı test adlarını birleştir
    for (var result in athlete1Results) {
      athlete1Map[result.testName] = result;
    }
    for (var result in athlete2Results) {
      athlete2Map[result.testName] = result;
    }

    // Aynı test adlarını birleştir ve en sonuncusunu al
    for (var entry in athlete1Map.entries) {
      if (athlete2Map.containsKey(entry.key)) {
        mergedResults.add(athlete2Map[entry.key]!); // Sporcu 2'nin sonucunu al
      } else {
        mergedResults.add(entry.value); // Sadece sporcu 1'in sonucunu al
      }
    }

    // Sporcu 2'de olup sporcu 1'de olmayanları ekle
    for (var entry in athlete2Map.entries) {
      if (!athlete1Map.containsKey(entry.key)) {
        mergedResults.add(entry.value);
      }
    }

    // Sonuçları test adına göre sırala
    mergedResults.sort((a, b) => a.testName.compareTo(b.testName));

    return mergedResults;
  }

  static pw.Widget _buildComparisonSinglePage(
    AthleteModel athlete1,
    AthleteModel athlete2,
    List<TestResultModel> athlete1Results,
    List<TestResultModel> athlete2Results,
    String comparisonAnalysis,
    pw.Font bebasFont,
  ) {
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
                  'Sporcu Karşılaştırma Raporu',
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
          
          // Sporcu bilgileri karşılaştırma tablosu
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
                          'Özellik',
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
                          'Sporcu 1',
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
                          'Sporcu 2',
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
                _buildTableRow('Ad Soyad', '${athlete1.name} ${athlete1.surname}', '${athlete2.name} ${athlete2.surname}', bebasFont),
                _buildTableRow('Yaş', '${DateTime.now().year - athlete1.birthDate.year} yaş', '${DateTime.now().year - athlete2.birthDate.year} yaş', bebasFont),
                _buildTableRow('Cinsiyet', athlete1.gender, athlete2.gender, bebasFont),
                _buildTableRow('Branş', athlete1.branch, athlete2.branch, bebasFont),
                _buildTableRow('Boy', '${athlete1.height} cm', '${athlete2.height} cm', bebasFont),
                _buildTableRow('Kilo', '${athlete1.weight} kg', '${athlete2.weight} kg', bebasFont),
              ],
            ),
          ),
          
          pw.SizedBox(height: 15),
          
          // Test sonuçları karşılaştırması
          if (athlete1Results.isNotEmpty || athlete2Results.isNotEmpty) ...[
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
                      color: _getPdfColor(AppTheme.accentColor),
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
                            'Sporcu 1',
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
                            'Sporcu 2',
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
                  
                  // Test sonuçları satırları
                  ..._getComparisonTestResults(athlete1Results, athlete2Results).take(4).map((result) => 
                    _buildTableRow(
                      result.testName,
                      '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                      '${result.result.toStringAsFixed(2)} ${result.resultUnit}',
                      bebasFont,
                    )
                  ).toList(),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],
          
          // AI Analiz başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
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
            child: pw.Row(
              children: [
                pw.Icon(
                  pw.IconData(0xe3b3), // psychology icon
                  color: PdfColors.white,
                  size: 20,
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Yapay Zeka Karşılaştırma Analizi',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: bebasFont,
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 10),
          
          // AI Analiz içeriği - Bölümlere ayrılmış
          ..._buildAnalysisSections(comparisonAnalysis, bebasFont),
          
          pw.SizedBox(height: 15),
          
          // Alt bilgi
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
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

  static pw.Widget _buildTableRow(String label, String value1, String value2, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
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
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _getPdfColor(AppTheme.primaryTextColor),
                font: bebasFont,
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value1,
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
              value2,
              style: pw.TextStyle(
                fontSize: 10,
                color: _getPdfColor(AppTheme.primaryTextColor),
                font: bebasFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<TestResultModel> _getComparisonTestResults(List<TestResultModel> athlete1Results, List<TestResultModel> athlete2Results) {
    final allResults = <TestResultModel>[];
    allResults.addAll(athlete1Results);
    allResults.addAll(athlete2Results);
    
    // Tarihe göre sırala ve en son 4 sonucu al
    allResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    return allResults.take(4).toList();
  }

  static List<pw.Widget> _buildAnalysisSections(String analysis, pw.Font bebasFont) {
    final sections = <pw.Widget>[];
    final parsedAnalysis = _parseAnalysis(analysis);

    if (parsedAnalysis.containsKey('degerlendirme')) {
      sections.add(_buildAnalysisSection('Değerlendirme', parsedAnalysis['degerlendirme']!, _getPdfColor(AppTheme.primaryColor), bebasFont));
    }
    if (parsedAnalysis.containsKey('eksik_guclu')) {
      sections.add(_buildAnalysisSection('Eksik Güçlü Alanlar', parsedAnalysis['eksik_guclu']!, _getPdfColor(AppTheme.accentColor), bebasFont));
    }
    if (parsedAnalysis.containsKey('genel_notlar')) {
      sections.add(_buildAnalysisSection('Genel Notlar', parsedAnalysis['genel_notlar']!, _getPdfColor(AppTheme.secondaryColor), bebasFont));
    }

    return sections;
  }

  static pw.Widget _buildAnalysisSection(String title, String content, PdfColor color, pw.Font bebasFont) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
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
            padding: const pw.EdgeInsets.all(12),
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
                fontSize: 14,
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
} 