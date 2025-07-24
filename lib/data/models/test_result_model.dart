class TestResultModel {
  final String id;
  final String testId;
  final String testName;
  final String athleteId;
  final String athleteName;
  final String athleteSurname;
  final DateTime testDate;
  final double result;
  final String resultUnit;
  final String? notes;
  final String? aiAnalysis;

  TestResultModel({
    required this.id,
    required this.testId,
    required this.testName,
    required this.athleteId,
    required this.athleteName,
    required this.athleteSurname,
    required this.testDate,
    required this.result,
    required this.resultUnit,
    this.notes,
    this.aiAnalysis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'testName': testName,
      'athleteId': athleteId,
      'athleteName': athleteName,
      'athleteSurname': athleteSurname,
      'testDate': testDate.millisecondsSinceEpoch,
      'result': result,
      'resultUnit': resultUnit,
      'notes': notes,
      'aiAnalysis': aiAnalysis,
    };
  }

  factory TestResultModel.fromMap(Map<String, dynamic> map) {
    double parseResult(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return TestResultModel(
      id: map['id'].toString(),
      testId: map['testId'].toString(),
      testName: map['testName'].toString(),
      athleteId: map['athleteId'].toString(),
      athleteName: map['athleteName'].toString(),
      athleteSurname: map['athleteSurname'].toString(),
      testDate: map['testDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['testDate'])
          : DateTime.tryParse(map['testDate'].toString()) ?? DateTime.now(),
      result: parseResult(map['result']),
      resultUnit: map['resultUnit'].toString(),
      notes: map['notes']?.toString(),
      aiAnalysis: map['aiAnalysis']?.toString(),
    );
  }
} 