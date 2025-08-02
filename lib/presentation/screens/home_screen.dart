import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/presentation/widgets/onboarding_widget.dart';
import 'package:athleticcoach/presentation/widgets/app_drawer_widget.dart';
import 'package:athleticcoach/presentation/widgets/recent_tests_card_widget.dart';
import 'package:athleticcoach/presentation/widgets/athlete_comparison_card_widget.dart';
import 'package:athleticcoach/presentation/widgets/athlete_stories_widget.dart';

// Widget türleri için enum
enum WidgetType {
  recentTests,
  athleteStories,
  athleteComparison,
}

// Home widget sınıfı
class HomeWidget {
  final WidgetType type;
  final String title;
  final String description;
  final IconData icon;
  final bool isEnabled;

  HomeWidget({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.isEnabled = true,
  });
}

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
  List<TestResultModel> _recentTestResults = [];
  bool _isLoadingRecentTestResults = true;
  
  // Widget sıralama sistemi
  List<HomeWidget> _widgets = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeWidgets();
    _loadWidgetOrder();
    _checkFirstLaunch();
    _loadRecentTests();
    _loadRecentTestResults();
  }

  void _initializeWidgets() {
    _widgets = [
      HomeWidget(
        type: WidgetType.recentTests,
        title: 'Son İncelenen Testler',
        description: 'Son görüntülenen test sonuçları',
        icon: Icons.history,
      ),
      HomeWidget(
        type: WidgetType.athleteStories,
        title: 'Sporcular',
        description: 'Sporcu profillerine hızlı erişim',
        icon: Icons.people,
      ),
      HomeWidget(
        type: WidgetType.athleteComparison,
        title: 'Sporcu Karşılaştırma',
        description: 'İki sporcuyu yapay zeka ile karşılaştırın',
        icon: Icons.compare_arrows,
      ),
    ];
  }

  Future<void> _loadWidgetOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getStringList('widget_order');
      
      if (savedOrder != null && savedOrder.isNotEmpty) {
        final List<HomeWidget> orderedWidgets = [];
        
        for (String typeString in savedOrder) {
          final widgetType = WidgetType.values.firstWhere(
            (type) => type.toString() == typeString,
            orElse: () => WidgetType.recentTests,
          );
          
          final widget = _widgets.firstWhere(
            (widget) => widget.type == widgetType,
            orElse: () => _widgets.first,
          );
          
          orderedWidgets.add(widget);
        }
        
        // Eksik widget'ları ekle
        for (HomeWidget widget in _widgets) {
          if (!orderedWidgets.any((w) => w.type == widget.type)) {
            orderedWidgets.add(widget);
          }
        }
        
        setState(() {
          _widgets = orderedWidgets;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan sıralamayı kullan
      print('Widget sıralaması yüklenirken hata: $e');
    }
  }

  Future<void> _saveWidgetOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderList = _widgets.map((widget) => widget.type.toString()).toList();
      await prefs.setStringList('widget_order', orderList);
    } catch (e) {
      print('Widget sıralaması kaydedilirken hata: $e');
    }
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

  Future<void> _loadRecentTestResults() async {
    try {
      final database = AthleteDatabase();
      final recentResults = await database.getRecentTestResults(limit: 5);
      
      if (mounted) {
        setState(() {
          _recentTestResults = recentResults;
          _isLoadingRecentTestResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecentTestResults = false;
        });
      }
    }
  }

  Future<void> _refreshRecentTests() async {
    await _loadRecentTests();
  }

  Future<void> _refreshRecentTestResults() async {
    await _loadRecentTestResults();
  }

  Future<void> _refreshAllData() async {
    setState(() {
      _isLoading = true;
      _isLoadingRecentTests = true;
    });
    await Future.wait([
      _loadRecentTests(),
      _loadRecentTestResults(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }



  Widget _buildWidgetsList() {
    if (_isEditMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _widgets.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final widget = _widgets.removeAt(oldIndex);
            _widgets.insert(newIndex, widget);
          });
          // Sıralama değiştiğinde kaydet
          _saveWidgetOrder();
        },
        itemBuilder: (context, index) {
          final widget = _widgets[index];
          return Container(
            key: ValueKey('widget_${widget.type}_$index'),
            margin: const EdgeInsets.only(bottom: 20),
            child: _buildEditableWidget(widget, index),
          );
        },
      );
    } else {
      return Column(
        children: _widgets.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              _buildLongPressWidget(widget),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      );
    }
  }

  Widget _buildEditableWidget(HomeWidget widget, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildWidget(widget),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.drag_handle,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongPressWidget(HomeWidget widget) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isEditMode = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Düzenleme modu aktif! Widget\'ları sürükleyerek sıralayabilirsiniz.'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Bitti',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                });
              },
            ),
          ),
        );
      },
      child: _buildWidget(widget),
    );
  }

  Widget _buildWidget(HomeWidget widget) {
    switch (widget.type) {
      case WidgetType.recentTests:
        return RecentTestsCardWidget(
          recentTests: _recentTests,
          isLoading: _isLoadingRecentTests,
          onRefresh: _refreshRecentTests,
          getTimeAgo: _getTimeAgo,
        );
      case WidgetType.athleteStories:
        return AthleteStoriesWidget(
          key: ValueKey('athlete_stories_${DateTime.now().millisecondsSinceEpoch}'),
          onAthleteUpdated: _refreshAllData,
        );
      case WidgetType.athleteComparison:
        return AthleteComparisonCardWidget(
          onAthleteUpdated: _refreshAllData,
        );
      default:
        return Container(); // Fallback widget
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Yardım',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ana Sayfa Özellikleri:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.drag_handle,
                'Widget Düzenleme',
                'Herhangi bir kartı uzun basarak düzenleme modunu aktif edebilirsiniz.',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                Icons.swap_vert,
                'Sıralama Değiştirme',
                'Düzenleme modunda kartları sürükleyip bırakarak sıralamayı değiştirebilirsiniz.',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                Icons.save,
                'Otomatik Kaydetme',
                'Yaptığınız değişiklikler otomatik olarak kaydedilir.',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                Icons.people,
                'Sporcu Ekleme',
                '"Sporcu Ekle" butonuna basarak yeni sporcu ekleyebilirsiniz.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Anladım',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
      drawerScrimColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
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
          _isEditMode ? 'Widget\'ları Düzenle' : 'Athletic Performance Coach',
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
        actions: [
          if (_isEditMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                });
              },
              child: Text(
                'Bitti',
                style: TextStyle(
                  color: AppTheme.whiteTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: AppTheme.whiteTextColor,
              size: 24,
            ),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
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
          child: _buildWidgetsList(),
        ),
      ),
    );
  }
} 