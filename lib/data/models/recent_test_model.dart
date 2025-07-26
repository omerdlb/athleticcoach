class RecentTestModel {
  final int? id;
  final String testName;
  final String athleteName;
  final String testDate;
  final DateTime viewedAt;

  RecentTestModel({
    this.id,
    required this.testName,
    required this.athleteName,
    required this.testDate,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testName': testName,
      'athleteName': athleteName,
      'testDate': testDate,
      'viewedAt': viewedAt.millisecondsSinceEpoch,
    };
  }

  factory RecentTestModel.fromMap(Map<String, dynamic> map) {
    return RecentTestModel(
      id: map['id'],
      testName: map['testName'],
      athleteName: map['athleteName'],
      testDate: map['testDate'],
      viewedAt: DateTime.fromMillisecondsSinceEpoch(map['viewedAt']),
    );
  }
} 