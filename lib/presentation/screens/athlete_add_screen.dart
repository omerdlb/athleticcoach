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
    'Futbol', 'Basketbol', 'Voleybol', 'Atletizm', 'Yüzme', 'Tenis', 'Güreş', 'Hentbol', 'Okçuluk',
    'Cimnastik', 'Boks', 'Halter', 'Judo', 'Karate', 'Masa Tenisi', 'Badminton', 'Kayak', 'Bisiklet',
    'Eskrim', 'Triatlon', 'Ragbi', 'Softbol', 'Squash', 'Taekwondo', 'Yelken', 'Diğer'
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sporcuyu Düzenle' : 'Sporcu Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'İsim'),
                validator: (value) => value == null || value.isEmpty ? 'İsim girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Soyisim'),
                validator: (value) => value == null || value.isEmpty ? 'Soyisim girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Doğum Tarihi',
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
                decoration: const InputDecoration(labelText: 'Cinsiyet'),
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
                decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Kilo girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Boy (cm)'),
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
                    decoration: const InputDecoration(labelText: 'Branş'),
                    validator: (value) => value == null || value.isEmpty ? 'Branş seçin' : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 