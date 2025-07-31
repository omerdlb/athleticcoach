import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/presentation/screens/test_result_detail_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';

class RecentTestResultsCardWidget extends StatelessWidget {
  final List<TestResultModel> recentResults;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(DateTime) getTimeAgo;

  const RecentTestResultsCardWidget({
    super.key,
    required this.recentResults,
    required this.isLoading,
    required this.onRefresh,
    required this.getTimeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 350,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width < 400 ? 300 : 400,
      ),
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
                  'Son Test Sonuçları',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  // Test sonuçları sayfasına git
                  onRefresh();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
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
          
          // Scroll edilebilir içerik
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : recentResults.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 32,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz test sonucu yok',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Test uyguladığınızda\nsonuçlar burada gözükecek',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: recentResults.map((result) => Column(
                            children: [
                              _buildRecentResultItem(context, result),
                              if (result != recentResults.last) const SizedBox(height: 12),
                            ],
                          )).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResultItem(BuildContext context, TestResultModel result) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TestResultDetailScreen(
              testName: result.testName,
              testId: result.testId,
              results: [result],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${(result.athleteName?.isNotEmpty == true ? result.athleteName![0] : "?")}${(result.athleteSurname?.isNotEmpty == true ? result.athleteSurname![0] : "")}',
                  style: TextStyle(
                    color: AppTheme.whiteTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Test Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.testName,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.athleteName ?? "Bilinmeyen"} ${result.athleteSurname ?? ""}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: const Color(0xFF9CA3AF).withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          getTimeAgo(result.testDate),
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 400 ? 10 : 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Sonuç
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${result.result.toStringAsFixed(1)} ${result.resultUnit}',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Ok İkonu
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 