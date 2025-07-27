import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/team_analysis_model.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/core/app_theme.dart';

class TeamAnalysisCardWidget extends StatelessWidget {
  final TeamAnalysisModel? latestTeamAnalysis;
  final bool isLoading;
  final Function(DateTime) getTimeAgo;

  const TeamAnalysisCardWidget({
    super.key,
    required this.latestTeamAnalysis,
    required this.isLoading,
    required this.getTimeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width < 400 ? 300 : 400,
      ),
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Ok İkonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Son Uygulanan Test Analizi',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showTeamAnalysisHistory(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Çizgi
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Analiz İçeriği
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : latestTeamAnalysis == null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 32,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz genel test analizi yok',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Yeni bir test uyguladığınızda\nburada analiz gösterilecek',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Test Bilgileri
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Test Bilgileri
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        latestTeamAnalysis!.testName,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 12,
                                            color: AppTheme.primaryColor.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${latestTeamAnalysis!.participantCount} katılımcı',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: const Color(0xFF9CA3AF).withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            getTimeAgo(latestTeamAnalysis!.createdAt),
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Analiz Metni
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                latestTeamAnalysis!.analysis,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                                  height: 1.5,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTeamAnalysisHistory(BuildContext context) async {
    try {
      final database = AthleteDatabase();
      final allAnalysis = await database.getAllTeamAnalysis();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Takım Analiz Geçmişi'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: allAnalysis.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz genel test analizi bulunmuyor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allAnalysis.length,
                      itemBuilder: (context, index) {
                        final analysis = allAnalysis[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      analysis.testName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${analysis.participantCount} katılımcı',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    getTimeAgo(analysis.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                analysis.analysis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppTheme.accentColor,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz geçmişi yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 