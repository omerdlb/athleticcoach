import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/presentation/screens/athlete_add_screen.dart';
import 'package:athleticcoach/presentation/screens/athlete_detail_screen.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/core/app_theme.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  final List<AthleteModel> _athletes = [];
  final List<AthleteModel> _filteredAthletes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    final athletes = await AthleteDatabase().getAllAthletes();
    setState(() {
      _athletes.clear();
      _athletes.addAll(athletes);
      _filteredAthletes.clear();
      _filteredAthletes.addAll(athletes);
      _loading = false;
    });
  }

  void _filterAthletes(String query) {
    setState(() {
      _filteredAthletes.clear();
      if (query.isEmpty) {
        _filteredAthletes.addAll(_athletes);
      } else {
        _filteredAthletes.addAll(
          _athletes.where((athlete) =>
            '${athlete.name} ${athlete.surname}'.toLowerCase().contains(query.toLowerCase())
          ),
        );
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _filterAthletes('');
      }
    });
  }

  Future<void> _addAthlete() async {
    final newAthlete = await Navigator.of(context).push<AthleteModel>(
      MaterialPageRoute(
        builder: (context) => const AthleteAddScreen(),
      ),
    );
    if (newAthlete != null) {
      await AthleteDatabase().insertAthlete(newAthlete);
      setState(() {
        _athletes.add(newAthlete);
        _filteredAthletes.add(newAthlete);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearchVisible
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width - 120,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterAthletes,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Sporcu ara...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.whiteTextColor.withOpacity(0.7)),
                    ),
                    style: TextStyle(color: AppTheme.whiteTextColor, fontSize: 16),
                  ),
                )
              : const Text('Sporcularım'),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearchVisible
                ? IconButton(
                    key: const ValueKey('close'),
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSearch,
                  )
                : IconButton(
                    key: const ValueKey('search'),
                    icon: const Icon(Icons.search),
                    onPressed: _toggleSearch,
                  ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _filteredAthletes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSearchVisible ? Icons.search_off : Icons.people_outline,
                        size: 64,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearchVisible ? 'Arama sonucu bulunamadı' : 'Henüz sporcu eklenmemiş',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSearchVisible 
                            ? 'Farklı bir arama terimi deneyin'
                            : 'Sporcu eklemek için + butonuna tıklayın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAthletes,
                  child: ListView.builder(
                    itemCount: _filteredAthletes.length,
                    itemBuilder: (context, index) {
                      final athlete = _filteredAthletes[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AthleteDetailScreen(athlete: athlete),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: index % 2 == 0
                                  ? [AppTheme.primaryColor.withOpacity(0.08), AppTheme.cardBackgroundColor]
                                  : [AppTheme.secondaryColor.withOpacity(0.08), AppTheme.cardBackgroundColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColorWithOpacity,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: athlete.gender == 'Kadın'
                                      ? AppTheme.femaleColor.withOpacity(0.2)
                                      : AppTheme.maleColor.withOpacity(0.2),
                                  child: Icon(
                                    athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                    color: athlete.gender == 'Kadın'
                                        ? AppTheme.femaleColor
                                        : AppTheme.maleColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${athlete.name} ${athlete.surname}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppTheme.primaryTextColor,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.sports, size: 16, color: AppTheme.primaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            athlete.branch,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.cake, size: 15, color: AppTheme.secondaryTextColor),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${athlete.birthDate.year}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.secondaryTextColor,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                            size: 15,
                                            color: AppTheme.secondaryTextColor,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            athlete.gender,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.secondaryTextColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 22, color: AppTheme.primaryColor),
                                  tooltip: 'Düzenle',
                                  onPressed: () async {
                                    final updatedAthlete = await Navigator.of(context).push<AthleteModel>(
                                      MaterialPageRoute(
                                        builder: (context) => AthleteAddScreen(athlete: athlete),
                                      ),
                                    );
                                    if (updatedAthlete != null) {
                                      await AthleteDatabase().updateAthlete(updatedAthlete);
                                      setState(() {
                                        final originalIndex = _athletes.indexWhere((a) => a.id == athlete.id);
                                        if (originalIndex != -1) {
                                          _athletes[originalIndex] = updatedAthlete;
                                        }
                                        final filteredIndex = _filteredAthletes.indexWhere((a) => a.id == athlete.id);
                                        if (filteredIndex != -1) {
                                          _filteredAthletes[filteredIndex] = updatedAthlete;
                                        }
                                      });
                                    }
                                  },
                                ),
                                Icon(Icons.arrow_forward_ios, size: 18, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAthlete,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: AppTheme.whiteTextColor),
                ),
    );
  }
} 