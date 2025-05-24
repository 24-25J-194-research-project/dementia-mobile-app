class OnboardingStatus {
  final String userId;
  final bool hasCompletedWelcome;
  final bool hasCompletedSidebarTutorial;
  final bool hasCompletedPatientProfile;
  final bool hasCompletedMemoriesTutorial;
  final bool hasCompletedTherapyTutorial;
  final DateTime? lastModified;

  OnboardingStatus({
    required this.userId,
    this.hasCompletedWelcome = false,
    this.hasCompletedSidebarTutorial = false,
    this.hasCompletedPatientProfile = false,
    this.hasCompletedMemoriesTutorial = false,
    this.hasCompletedTherapyTutorial = false,
    this.lastModified,
  });

  bool get isPhaseOneComplete =>
      hasCompletedWelcome &&
      hasCompletedSidebarTutorial &&
      hasCompletedPatientProfile;

  bool get isPhaseTwoComplete =>
      isPhaseOneComplete &&
      hasCompletedMemoriesTutorial &&
      hasCompletedTherapyTutorial;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'hasCompletedWelcome': hasCompletedWelcome,
      'hasCompletedSidebarTutorial': hasCompletedSidebarTutorial,
      'hasCompletedPatientProfile': hasCompletedPatientProfile,
      'hasCompletedMemoriesTutorial': hasCompletedMemoriesTutorial,
      'hasCompletedTherapyTutorial': hasCompletedTherapyTutorial,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      userId: json['userId'],
      hasCompletedWelcome: json['hasCompletedWelcome'] ?? false,
      hasCompletedSidebarTutorial: json['hasCompletedSidebarTutorial'] ?? false,
      hasCompletedPatientProfile: json['hasCompletedPatientProfile'] ?? false,
      hasCompletedMemoriesTutorial:
          json['hasCompletedMemoriesTutorial'] ?? false,
      hasCompletedTherapyTutorial: json['hasCompletedTherapyTutorial'] ?? false,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }

  OnboardingStatus copyWith({
    String? userId,
    bool? hasCompletedWelcome,
    bool? hasCompletedSidebarTutorial,
    bool? hasCompletedPatientProfile,
    bool? hasCompletedMemoriesTutorial,
    bool? hasCompletedTherapyTutorial,
    DateTime? lastModified,
  }) {
    return OnboardingStatus(
      userId: userId ?? this.userId,
      hasCompletedWelcome: hasCompletedWelcome ?? this.hasCompletedWelcome,
      hasCompletedSidebarTutorial:
          hasCompletedSidebarTutorial ?? this.hasCompletedSidebarTutorial,
      hasCompletedPatientProfile:
          hasCompletedPatientProfile ?? this.hasCompletedPatientProfile,
      hasCompletedMemoriesTutorial:
          hasCompletedMemoriesTutorial ?? this.hasCompletedMemoriesTutorial,
      hasCompletedTherapyTutorial:
          hasCompletedTherapyTutorial ?? this.hasCompletedTherapyTutorial,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
