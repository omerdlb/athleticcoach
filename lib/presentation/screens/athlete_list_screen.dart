import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/presentation/screens/athlete_add_screen.dart';
import 'package:athleticcoach/presentation/screens/athlete_detail_screen.dart';
import 'package:athleticcoach/data/athlete_database.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  final List<AthleteModel> _athletes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    final athletes = await AthleteDatabase().getAllAthletes();
    setState(() {
      _athletes.clear();
      _athletes.addAll(athletes);
      _loading = false;
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporcular'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Sporcu Ekle',
            onPressed: _addAthlete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _athletes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz sporcu eklenmemiş',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sporcu eklemek için + butonuna tıklayın',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAthletes,
                  child: ListView.builder(
                    itemCount: _athletes.length,
                    itemBuilder: (context, index) {
                      final athlete = _athletes[index];
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
                                  ? [colorScheme.primary.withOpacity(0.08), Colors.white]
                                  : [colorScheme.secondary.withOpacity(0.08), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.07),
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
                                      ? colorScheme.secondaryContainer
                                      : colorScheme.primaryContainer,
                                  child: Icon(
                                    athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                    color: athlete.gender == 'Kadın'
                                        ? colorScheme.secondary
                                        : colorScheme.primary,
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
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.sports, size: 16, color: colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            athlete.branch,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.cake, size: 15, color: colorScheme.outline),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${athlete.birthDate.year}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            athlete.gender == 'Kadın' ? Icons.female : Icons.male,
                                            size: 15,
                                            color: colorScheme.outline,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            athlete.gender,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 22),
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
                                        _athletes[index] = updatedAthlete;
                                      });
                                    }
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF6366F1)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 