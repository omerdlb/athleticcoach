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
  final String sessionId;

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
    required this.sessionId,
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
      'sessionId': sessionId,
    };
  }

  factory TestResultModel.fromMap(Map<String, dynamic> map) {
    double parseResult(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    // testDate parsing için debug bilgisi
    DateTime parseTestDate(dynamic testDateValue) {
      print('=== TEST DATE PARSING ===');
      print('Test ID: ${map['id']}');
      print('Test Name: ${map['testName']}');
      print('Raw testDate value: $testDateValue');
      print('Value type: ${testDateValue.runtimeType}');
      
      DateTime result;
      if (testDateValue is int) {
        result = DateTime.fromMillisecondsSinceEpoch(testDateValue);
        print('Parsed as int (milliseconds): $result');
      } else if (testDateValue is String) {
        final parsed = DateTime.tryParse(testDateValue);
        if (parsed != null) {
          result = parsed;
          print('Parsed as string: $result');
        } else {
          // Eğer parse edilemezse, bugünün tarihi yerine epoch time kullan
          print('ERROR: Could not parse testDate string: $testDateValue');
          result = DateTime.fromMillisecondsSinceEpoch(0); // 1970-01-01
          print('Using epoch time as fallback: $result');
        }
      } else {
        print('ERROR: Unknown testDate type: ${testDateValue.runtimeType}');
        result = DateTime.fromMillisecondsSinceEpoch(0); // 1970-01-01
        print('Using epoch time as fallback: $result');
      }
      
      print('Final result: $result');
      print('==========================');
      return result;
    }
    
    return TestResultModel(
      id: map['id'].toString(),
      testId: map['testId'].toString(),
      testName: map['testName'].toString(),
      athleteId: map['athleteId'].toString(),
      athleteName: map['athleteName'].toString(),
      athleteSurname: map['athleteSurname'].toString(),
      testDate: parseTestDate(map['testDate']),
      result: parseResult(map['result']),
      resultUnit: map['resultUnit'].toString(),
      notes: map['notes'],
      aiAnalysis: map['aiAnalysis'],
      sessionId: map['sessionId']?.toString() ?? '',
    );
  }
} 