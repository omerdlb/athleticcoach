import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/services/pdf_export_service.dart';
import 'package:athleticcoach/core/app_theme.dart';
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
  @override
  Widget build(BuildContext context) {
    if (widget.testResult.aiAnalysis == null || widget.testResult.aiAnalysis!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Analizi'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.whiteTextColor,
          elevation: 2,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'AI Analizi Bulunamadı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu test sonucu için henüz AI analizi yapılmamış',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                await PdfExportService.exportTestAnalysis(widget.testResult);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('PDF başarıyla oluşturuldu!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF oluşturulurken hata: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            tooltip: 'PDF Olarak Dışa Aktar',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientDecoration,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Bilgileri
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Test Bilgileri',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Sporcu', '${widget.testResult.athleteName} ${widget.testResult.athleteSurname}'),
                    _buildInfoRow('Test', widget.testResult.testName),
                    _buildInfoRow('Sonuç', '${widget.testResult.result.toStringAsFixed(2)} ${widget.testResult.resultUnit}'),
                    _buildInfoRow('Tarih', '${widget.testResult.testDate.day.toString().padLeft(2, '0')}.${widget.testResult.testDate.month.toString().padLeft(2, '0')}.${widget.testResult.testDate.year}'),
                    if (widget.testResult.notes?.isNotEmpty == true)
                      _buildInfoRow('Notlar', widget.testResult.notes!),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // AI Analizi - Tek Kart
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Performans Analizi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tam analiz metni
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: _buildFormattedAnalysis(widget.testResult.aiAnalysis!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAnalysis(String analysis) {
    final lines = analysis.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, height: 1.6)),
                Expanded(
                  child: Text(trimmed.substring(1).trim(),
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                ),
              ],
            ),
          );
        } else if (RegExp(r'^[0-9]+\.').hasMatch(trimmed)) {
          // Başlık
          final title = trimmed.replaceFirst(RegExp(r'^[0-9]+\.'), '').trim();
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(trimmed,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
          );
        }
      }).toList(),
    );
  }
} 