import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:flutter/material.dart';

class AthleteAddScreen extends StatefulWidget {
  final AthleteModel? athlete;
  const AthleteAddScreen({super.key, this.athlete});

  @override
  State<AthleteAddScreen> createState() => _AthleteAddScreenState();
}

class _AthleteAddScreenState extends State<AthleteAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _branchController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedBranch;

  final List<String> _branches = [
    // Takım Sporları
    'Futbol', 'Basketbol', 'Voleybol', 'Hentbol', 'Ragbi', 'Beyzbol', 'Softbol', 'Amerikan Futbolu',
    // Bireysel Sporlar
    'Atletizm', 'Yüzme', 'Tenis', 'Masa Tenisi', 'Badminton', 'Squash', 'Golf', 'Okçuluk', 'Bisiklet', 'Triatlon', 'Maraton',
    // Su Sporları
    'Yelken', 'Kürek', 'Kano', 'Sörf', 'Su Topu', 'Dalgıçlık', 'Su Kayağı',
    // Kış Sporları
    'Kayak', 'Snowboard', 'Buz Pateni', 'Buz Hokeyi', 'Curling',
    // Dövüş Sporları
    'Judo', 'Karate', 'Taekwondo', 'Boks', 'Kickboks', 'Muay Thai', 'Güreş', 'Eskrim', 'MMA', 'Krav Maga', 'Aikido', 'Kung Fu', 'Wushu', 'Sambo',
    // Güç ve Fitness
    'Cimnastik', 'Halter', 'Crossfit', 'Fitness', 'Bodybuilding', 'Pilates', 'Yoga', 'Dans',
    // Doğa ve Motor Sporları
    'Motor Sporları', 'Binicilik', 'Dağcılık', 'Tırmanış', 'Orienteering', 'Okçuluk', 'Parkur',
    // Zihin ve Modern Sporlar
    'Satranç', 'E-Spor',
    // Diğer
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.athlete != null) {
      final a = widget.athlete!;
      _nameController.text = a.name;
      _surnameController.text = a.surname;
      _selectedBirthDate = a.birthDate;
      _birthDateController.text = "${a.birthDate.day}/${a.birthDate.month}/${a.birthDate.year}";
      _selectedGender = a.gender;
      _weightController.text = a.weight.toString();
      _heightController.text = a.height.toString();
      _selectedBranch = a.branch;
      _branchController.text = a.branch;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.athlete != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sporcuyu Düzenle' : 'Sporcu Ekle'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5FE), Color(0xFFFDF6E3)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
          ),
        ],
      ),
                child: Form(
        key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
            children: [
                      // Avatar ve başlık
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: _selectedGender == 'Kadın'
                            ? colorScheme.secondaryContainer
                            : colorScheme.primaryContainer,
                        child: Icon(
                          _selectedGender == 'Kadın' ? Icons.female : Icons.male,
                          color: _selectedGender == 'Kadın'
                              ? colorScheme.secondary
                              : colorScheme.primary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEdit ? 'Sporcuyu Düzenle' : 'Yeni Sporcu Ekle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      // Form alanları
              TextFormField(
                controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'İsim',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                validator: (value) => value == null || value.isEmpty ? 'İsim girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                        decoration: InputDecoration(
                          labelText: 'Soyisim',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                validator: (value) => value == null || value.isEmpty ? 'Soyisim girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Doğum Tarihi',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthDate ?? DateTime(2005),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedBirthDate = pickedDate;
                          _birthDateController.text =
                              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                validator: (value) => value == null || value.isEmpty ? 'Doğum tarihi seçin' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Cinsiyet',
                          prefixIcon: const Icon(Icons.wc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                items: ['Erkek', 'Kadın']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) => value == null ? 'Cinsiyet seçin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Kilo (kg)',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Kilo girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                        decoration: InputDecoration(
                          labelText: 'Boy (cm)',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Boy girin' : null,
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return _branches;
                  }
                  return _branches.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                initialValue: TextEditingValue(text: _selectedBranch ?? ''),
                onSelected: (String selection) {
                  setState(() {
                    _selectedBranch = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  controller.text = _selectedBranch ?? '';
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Branş',
                              prefixIcon: const Icon(Icons.sports),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                    validator: (value) => value == null || value.isEmpty ? 'Branş seçin' : null,
                  );
                },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 260, minWidth: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(isEdit ? 'Kaydet' : 'Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final athlete = AthleteModel(
                                id: isEdit ? widget.athlete!.id : DateTime.now().toIso8601String(),
                                name: _nameController.text,
                                surname: _surnameController.text,
                                birthDate: _selectedBirthDate!,
                                gender: _selectedGender!,
                                weight: double.parse(_weightController.text),
                                height: double.parse(_heightController.text),
                                branch: _selectedBranch!,
                              );
                              Navigator.of(context).pop(athlete);
                            }
                          },
                        ),
              ),
            ],
          ),
        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 