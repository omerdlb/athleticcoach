import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/data/models/team_analysis_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/presentation/widgets/onboarding_widget.dart';
import 'package:athleticcoach/presentation/widgets/app_drawer_widget.dart';
import 'package:athleticcoach/presentation/widgets/recent_tests_card_widget.dart';
import 'package:athleticcoach/presentation/widgets/team_analysis_card_widget.dart';
import 'package:athleticcoach/presentation/screens/yo_yo_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFirstLaunch = false;
  bool _isLoading = true;
  List<RecentTestModel> _recentTests = [];
  bool _isLoadingRecentTests = true;
  TeamAnalysisModel? _latestTeamAnalysis;
  bool _isLoadingTeamAnalysis = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _loadRecentTests();
    _loadTeamAnalysis();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (_isFirstLaunch) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          OnboardingWidget.showOnboarding(context);
        });
      }
    }
  }

  Future<void> _loadRecentTests() async {
    try {
      final database = AthleteDatabase();
      final recentTests = await database.getRecentTests(limit: 3);
      
      if (mounted) {
        setState(() {
          _recentTests = recentTests;
          _isLoadingRecentTests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecentTests = false;
        });
      }
    }
  }

  Future<void> _loadTeamAnalysis() async {
    try {
      final database = AthleteDatabase();
      final teamAnalysis = await database.getLatestTeamAnalysis();
      
      if (mounted) {
        setState(() {
          _latestTeamAnalysis = teamAnalysis;
          _isLoadingTeamAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeamAnalysis = false;
        });
      }
    }
  }

  Future<void> _refreshRecentTests() async {
    await _loadRecentTests();
  }

  Widget _buildYoYoQuickAccessCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColorWithOpacity,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const YoYoTestScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.whiteTextColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: AppTheme.whiteTextColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yo-Yo IR1 Test',
                        style: TextStyle(
                          color: AppTheme.whiteTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senkronize bip sesi ile test yönetimi',
                        style: TextStyle(
                          color: AppTheme.whiteTextColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.whiteTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 gün önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 hafta önce' : '$weeks hafta önce';
      } else {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 ay önce' : '$months ay önce';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 saat önce' : '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 dakika önce' : '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: AppTheme.whiteTextColor,
              size: 28,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          'Athletic Performance Coach',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppTheme.getResponsiveFontSize(context, 22),
            color: AppTheme.whiteTextColor,
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawerWidget.buildDrawer(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientDecoration,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.getResponsivePadding(context).left,
            MediaQuery.of(context).padding.top + 80,
            AppTheme.getResponsivePadding(context).right,
            AppTheme.getResponsivePadding(context).bottom,
          ),
            child: Column(
              children: [
              // Yo-Yo Test Hızlı Erişim Kartı
              _buildYoYoQuickAccessCard(),
              
              const SizedBox(height: 20),
              
              // Son İncelenen Testler Kartı
              RecentTestsCardWidget(
                recentTests: _recentTests,
                isLoading: _isLoadingRecentTests,
                onRefresh: _refreshRecentTests,
                getTimeAgo: _getTimeAgo,
              ),
              
              // Son Uygulanan Test Analizi Kartı
              TeamAnalysisCardWidget(
                latestTeamAnalysis: _latestTeamAnalysis,
                isLoading: _isLoadingTeamAnalysis,
                getTimeAgo: _getTimeAgo,
              ),
              
              
            ],
          ),
        ),
      ),
    );
  }
} 