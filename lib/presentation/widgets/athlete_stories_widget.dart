import 'package:flutter/material.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/presentation/screens/athlete_detail_screen.dart';
import 'package:athleticcoach/presentation/screens/athlete_add_screen.dart';

class AthleteStoriesWidget extends StatefulWidget {
  final VoidCallback? onAthleteUpdated;
  
  const AthleteStoriesWidget({
    super.key,
    this.onAthleteUpdated,
  });

  @override
  State<AthleteStoriesWidget> createState() => _AthleteStoriesWidgetState();
}



class _AthleteStoriesWidgetState extends State<AthleteStoriesWidget> {
  List<AthleteModel> _athletes = [];
  bool _isLoading = true;

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
        print('Sporcular yüklendi: ${athletes.length} adet'); // Debug için
      }
    } catch (e) {
      print('Sporcu yükleme hatası: $e'); // Debug için
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    print('Sporcu listesi yenileniyor...'); // Debug için
    setState(() {
      _isLoading = true;
    });
    await _loadAthletes();
    print('Sporcu listesi yenilendi. Toplam: ${_athletes.length}'); // Debug için
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_athletes.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: GestureDetector(
            onTap: () async {
              // Sporcu ekleme ekranına git
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AthleteAddScreen(),
                ),
              );
              
              // Kısa bir bekleme süresi ekle (veritabanı güncellemesi için)
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Her zaman listeyi yenile (sporcu eklenmiş olabilir)
              await refresh();
              // Ana sayfayı da güncelle
              widget.onAthleteUpdated?.call();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sporcu Ekle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _athletes.length,
        itemBuilder: (context, index) {
          final athlete = _athletes[index];
          
          return GestureDetector(
            onTap: () async {
              // Sporcunun profil sayfasına git
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AthleteDetailScreen(athlete: athlete),
                ),
              );
              
              // Eğer sporcu güncellendi veya silindi ise listeyi yenile
              if (result == true) {
                refresh();
                // Ana sayfayı da güncelle
                widget.onAthleteUpdated?.call();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: athlete.gender == 'Kadın'
                            ? [AppTheme.femaleColor, AppTheme.femaleColor.withOpacity(0.7)]
                            : [AppTheme.maleColor, AppTheme.maleColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        athlete.gender == 'Kadın' ? Icons.face_retouching_natural : Icons.face,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Text(
                      '${athlete.name} ${athlete.surname}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 