import 'package:flutter/material.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:athleticcoach/services/pdf_export_service.dart';

class AthleteComparisonCardWidget extends StatefulWidget {
  const AthleteComparisonCardWidget({
    super.key,
  });

  @override
  State<AthleteComparisonCardWidget> createState() => _AthleteComparisonCardWidgetState();
}

class _AthleteComparisonCardWidgetState extends State<AthleteComparisonCardWidget> {
  List<AthleteModel> _athletes = [];
  bool _isLoading = true;
  AthleteModel? _selectedAthlete1;
  AthleteModel? _selectedAthlete2;
  String? _comparisonResult;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    try {
      final database = AthleteDatabase();
      final athletes = await database.getAllAthletes();
      
      if (mounted) {
        setState(() {
          _athletes = athletes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _compareAthletes() async {
    if (_selectedAthlete1 == null || _selectedAthlete2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen iki sporcu seçin'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isComparing = true;
      _comparisonResult = null;
    });

    try {
      final database = AthleteDatabase();
      
      // Her iki sporcunun test sonuçlarını al
      final athlete1Results = await database.getTestResultsByAthleteId(_selectedAthlete1!.id);
      final athlete2Results = await database.getTestResultsByAthleteId(_selectedAthlete2!.id);

      // Gemini servisi ile karşılaştırma yap
      final comparison = await GeminiService.compareAthletes(
        athlete1: _selectedAthlete1!,
        athlete2: _selectedAthlete2!,
        athlete1Results: athlete1Results,
        athlete2Results: athlete2Results,
      );

      if (mounted) {
        setState(() {
          _comparisonResult = comparison;
          _isComparing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isComparing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karşılaştırma sırasında hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (_selectedAthlete1 == null || _selectedAthlete2 == null || _comparisonResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önce karşılaştırma yapın'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final database = AthleteDatabase();
      
      // Her iki sporcunun test sonuçlarını al
      final athlete1Results = await database.getTestResultsByAthleteId(_selectedAthlete1!.id);
      final athlete2Results = await database.getTestResultsByAthleteId(_selectedAthlete2!.id);

      // PDF export
      await PdfExportService.exportAthleteComparison(
        athlete1: _selectedAthlete1!,
        athlete2: _selectedAthlete2!,
        athlete1Results: athlete1Results,
        athlete2Results: athlete2Results,
        comparisonAnalysis: _comparisonResult!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF başarıyla oluşturuldu'),
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
  }

  void _resetComparison() {
    setState(() {
      _selectedAthlete1 = null;
      _selectedAthlete2 = null;
      _comparisonResult = null;
      _isComparing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Karşılaştırma sıfırlandı'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [AppTheme.secondaryColor.withOpacity(0.08), AppTheme.cardBackgroundColor]
              : [AppTheme.secondaryColor.withOpacity(0.12), AppTheme.cardBackgroundColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColorWithOpacity,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sporcu Karşılaştırma',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 20,
                              color: AppTheme.primaryTextColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İki sporcuyu yapay zeka ile karşılaştırın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryTextColor,
                              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
            else if (_athletes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz sporcu bulunmuyor',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sporcu ekleyerek karşılaştırma yapabilirsiniz',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Sporcu seçimi - Responsive tasarım
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Geniş ekranlar için yan yana
                        return Row(
                          children: [
                            Expanded(
                              child: _buildAthleteDropdown(
                                '1. Sporcu',
                                _selectedAthlete1,
                                (athlete) => setState(() => _selectedAthlete1 = athlete),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAthleteDropdown(
                                '2. Sporcu',
                                _selectedAthlete2,
                                (athlete) => setState(() => _selectedAthlete2 = athlete),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Dar ekranlar için alt alta
                        return Column(
                          children: [
                            _buildAthleteDropdown(
                              '1. Sporcu',
                              _selectedAthlete1,
                              (athlete) => setState(() => _selectedAthlete1 = athlete),
                            ),
                            const SizedBox(height: 16),
                            _buildAthleteDropdown(
                              '2. Sporcu',
                              _selectedAthlete2,
                              (athlete) => setState(() => _selectedAthlete2 = athlete),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Butonlar - Karşılaştır ve Sıfırla
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedAthlete1 != null && _selectedAthlete2 != null && !_isComparing
                              ? _compareAthletes
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.whiteTextColor,
                            padding: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isComparing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteTextColor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Karşılaştırılıyor...',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Karşılaştır',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          onPressed: (_selectedAthlete1 != null || _selectedAthlete2 != null || _comparisonResult != null) && !_isComparing
                              ? _resetComparison
                              : null,
                          icon: Icon(
                            Icons.refresh,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          tooltip: 'Sıfırla',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 18 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Karşılaştırma sonucu
                  if (_comparisonResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
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
                              Text(
                                'Yapay Zeka Analizi',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _exportToPdf,
                                icon: Icon(
                                  Icons.picture_as_pdf,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                tooltip: 'PDF olarak dışarı aktar',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _comparisonResult!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryTextColor,
                                  height: 1.5,
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteDropdown(String label, AthleteModel? selectedAthlete, Function(AthleteModel?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<AthleteModel>(
            value: selectedAthlete,
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Sporcu seçin',
              hintStyle: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 14,
            ),
            items: _athletes.map((athlete) {
              return DropdownMenuItem<AthleteModel>(
                value: athlete,
                child: Row(
                  children: [
                    Icon(
                      athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                      size: 16,
                      color: athlete.gender == 'Kadın' ? AppTheme.femaleColor : AppTheme.maleColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${athlete.name} ${athlete.surname}',
                        style: TextStyle(
                          color: AppTheme.primaryTextColor,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
} 