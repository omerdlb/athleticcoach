import 'package:flutter/material.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/core/app_theme.dart';

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

  final List<String> _genders = ['Erkek', 'Kadın'];

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sporcuyu Düzenle' : 'Sporcu Ekle',
          style: TextStyle(
            color: AppTheme.whiteTextColor,
            fontWeight: FontWeight.w600,
          ),
      ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.whiteTextColor),
      ),
      body: Container(
        decoration: AppTheme.gradientDecoration,
        child: SafeArea(
            child: SingleChildScrollView(
            padding: AppTheme.getResponsivePadding(context),
            child: Column(
              children: [
                // Avatar and title card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
            children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _selectedGender == 'Kadın'
                            ? AppTheme.femaleColor.withOpacity(0.2)
                            : AppTheme.maleColor.withOpacity(0.2),
                        child: Icon(
                          _selectedGender == 'Kadın' ? Icons.female : Icons.male,
                          color: _selectedGender == 'Kadın'
                              ? AppTheme.femaleColor
                              : AppTheme.maleColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEdit ? 'Sporcuyu Düzenle' : 'Yeni Sporcu Ekle',
                        style: TextStyle(
                          fontSize: 20,
                              fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                            ),
                      ),

                const SizedBox(height: 20),

                // Form fields card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // İsim
              TextFormField(
                controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'İsim',
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                        ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'İsim girin';
                            }
                            return null;
                          },
              ),
                        
              const SizedBox(height: 16),
                        
                        // Soyisim
              TextFormField(
                controller: _surnameController,
                        decoration: InputDecoration(
                          labelText: 'Soyisim',
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                        ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Soyisim girin';
                            }
                            return null;
                          },
              ),
                        
              const SizedBox(height: 16),
                        
                        // Doğum Tarihi
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                        context: context,
                              initialDate: _selectedBirthDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                      );
                            if (picked != null && picked != _selectedBirthDate) {
                        setState(() {
                                _selectedBirthDate = picked;
                        });
                      }
                    },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedBirthDate != null
                                      ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                      : 'Doğum Tarihi Seçin',
                                  style: TextStyle(
                                    color: _selectedBirthDate != null 
                                        ? AppTheme.primaryTextColor 
                                        : AppTheme.secondaryTextColor,
              ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
              const SizedBox(height: 16),
                        
                        // Cinsiyet
              DropdownButtonFormField<String>(
                value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Cinsiyet',
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            prefixIcon: Icon(Icons.person_add, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                          ),
                          items: _genders.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                  setState(() {
                              _selectedGender = newValue!;
                  });
                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Cinsiyet seçin';
                            }
                            return null;
                          },
              ),
                        
              const SizedBox(height: 16),
                        
                        // Kilo
              TextFormField(
                controller: _weightController,
                          keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Kilo (kg)',
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            prefixIcon: Icon(Icons.monitor_weight, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kilo girin';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            if (weight <= 0 || weight > 500) {
                              return 'Kilo 1-500 kg arasında olmalı';
                            }
                            return null;
                          },
              ),
                        
              const SizedBox(height: 16),
                        
                        // Boy
              TextFormField(
                controller: _heightController,
                          keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Boy (cm)',
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            prefixIcon: Icon(Icons.height, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Boy girin';
                            }
                            final height = double.tryParse(value);
                            if (height == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            if (height <= 0 || height > 300) {
                              return 'Boy 1-300 cm arasında olmalı';
                            }
                            return null;
                          },
              ),
                        
              const SizedBox(height: 16),
                        
                        // Branş
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
                                labelStyle: TextStyle(color: AppTheme.primaryColor),
                                prefixIcon: Icon(Icons.sports, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                                ),
                            ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Branş seçin';
                                }
                                // Branş listesinde var mı kontrol et
                                if (!_branches.contains(value)) {
                                  return 'Geçerli bir branş seçin';
                                }
                                return null;
                              },
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
                        
                        const SizedBox(height: 24),
                        
                        // Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                          height: 50,
                        child: ElevatedButton.icon(
                            icon: Icon(Icons.save, color: AppTheme.whiteTextColor),
                            label: Text(
                              isEdit ? 'Kaydet' : 'Ekle',
                              style: TextStyle(
                                color: AppTheme.whiteTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.whiteTextColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            elevation: 4,
                          ),
                          onPressed: () {
                              // Form validasyonu
                            if (_formKey.currentState!.validate()) {
                                // Ek validasyonlar
                                final weight = double.tryParse(_weightController.text);
                                final height = double.tryParse(_heightController.text);
                                
                                // Kilo kontrolü
                                if (weight == null || weight <= 0 || weight > 500) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Geçerli bir kilo girin (1-500 kg)'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Boy kontrolü
                                if (height == null || height <= 0 || height > 300) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Geçerli bir boy girin (1-300 cm)'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Branş kontrolü
                                if (_selectedBranch == null || !_branches.contains(_selectedBranch)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Geçerli bir branş seçin'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Tüm validasyonlar geçti, sporcuyu kaydet
                              final athlete = AthleteModel(
                                id: isEdit ? widget.athlete!.id : DateTime.now().toIso8601String(),
                                name: _nameController.text,
                                surname: _surnameController.text,
                                birthDate: _selectedBirthDate!,
                                gender: _selectedGender!,
                                  weight: weight,
                                  height: height,
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
                const SizedBox(height: 100), // Added for keyboard spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
} 