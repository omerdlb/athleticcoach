class TeamAnalysisModel {
  final int? id;
  final String testSessionId;
  final String testName;
  final String analysis;
  final DateTime createdAt;
  final int participantCount;

  TeamAnalysisModel({
    this.id,
    required this.testSessionId,
    required this.testName,
    required this.analysis,
    required this.createdAt,
    required this.participantCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testSessionId': testSessionId,
      'testName': testName,
      'analysis': analysis,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'participantCount': participantCount,
    };
  }

  factory TeamAnalysisModel.fromMap(Map<String, dynamic> map) {
    return TeamAnalysisModel(
      id: map['id'],
      testSessionId: map['testSessionId'],
      testName: map['testName'],
      analysis: map['analysis'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      participantCount: map['participantCount'],
    );
  }
} 