class TestDefinitionModel {
  final String id;
  final String name;
  final String category;
  final String description; // Kısa açıklama
  final String protocol;    // Detaylı uygulama protokolü
  final String resultUnit;

  TestDefinitionModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.protocol,
    required this.resultUnit,
  });
} 