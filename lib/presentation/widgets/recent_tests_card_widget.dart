import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/data/predefined_data.dart';
import 'package:athleticcoach/presentation/screens/test_library_screen.dart';
import 'package:athleticcoach/presentation/screens/test_protocol_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';

class RecentTestsCardWidget extends StatelessWidget {
  final List<RecentTestModel> recentTests;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(DateTime) getTimeAgo;

  const RecentTestsCardWidget({
    super.key,
    required this.recentTests,
    required this.isLoading,
    required this.onRefresh,
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
                  'Son İncelenen Testler',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestLibraryScreen(),
                    ),
                  );
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
                : recentTests.isEmpty
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
                                'Henüz testleri incelemediniz',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Test protokolünü incelediğinizde\nburada gözükecek',
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
                          children: recentTests.map((test) => Column(
                            children: [
                              _buildRecentTestItem(
                                context,
                                test.testName,
                                test.athleteName,
                                getTimeAgo(test.viewedAt),
                                test,
                              ),
                              if (test != recentTests.last) const SizedBox(height: 12),
                            ],
                          )).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTestItem(BuildContext context, String title, String athleteName, String date, RecentTestModel test) {
    return GestureDetector(
      onTap: () {
        final testDefinition = _findTestDefinition(title);
        if (testDefinition != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TestProtocolScreen(
                test: testDefinition,
              ),
            ),
          );
        }
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
            // Test İkonu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.analytics,
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
                    title,
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
                        Icons.access_time,
                        size: 12,
                        color: const Color(0xFF9CA3AF).withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
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

  TestDefinitionModel? _findTestDefinition(String testName) {
    try {
      return predefinedTests.firstWhere((test) => test.name == testName);
    } catch (e) {
      return null;
    }
  }
} 