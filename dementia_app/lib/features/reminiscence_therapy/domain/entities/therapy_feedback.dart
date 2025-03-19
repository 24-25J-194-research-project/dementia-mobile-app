class TherapyFeedback {
  final String patientId;
  final String memoryId;
  final String therapyOutlineId;
  final List<String> selectedEmotions;
  final double rating;
  final String? comments;

  TherapyFeedback({
    required this.patientId,
    required this.memoryId,
    required this.therapyOutlineId,
    required this.selectedEmotions,
    required this.rating,
    this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'memoryId': memoryId,
      'therapyOutlineId': therapyOutlineId,
      'selectedEmotions': selectedEmotions,
      'rating': rating,
      'comments': comments,
    };
  }

  factory TherapyFeedback.fromMap(Map<String, dynamic> map) {
    return TherapyFeedback(
      patientId: map['patientId'],
      memoryId: map['memoryId'],
      therapyOutlineId: map['therapyOutlineId'],
      selectedEmotions: List<String>.from(map['selectedEmotions']),
      rating: map['rating'],
      comments: map['comments'],
    );
  }
}
