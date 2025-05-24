import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_status.dart';

class OnboardingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  OnboardingStatus? _onboardingStatus;
  bool _isLoading = false;

  OnboardingStatus? get onboardingStatus => _onboardingStatus;
  bool get isLoading => _isLoading;

  Future<void> loadOnboardingStatus(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc =
          await _firestore.collection('onboarding_status').doc(userId).get();

      if (doc.exists) {
        _onboardingStatus = OnboardingStatus.fromJson({
          ...doc.data()!,
          'userId': userId,
        });
      } else {
        // Create new onboarding status if it doesn't exist
        _onboardingStatus = OnboardingStatus(
          userId: userId,
          lastModified: DateTime.now(),
        );
        await _saveOnboardingStatus();
      }
    } catch (e) {
      debugPrint('Error loading onboarding status: $e');
      // Create a default status in case of error
      _onboardingStatus = OnboardingStatus(
        userId: userId,
        lastModified: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeWelcome() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedWelcome: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> completeSidebarTutorial() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedSidebarTutorial: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> completePatientProfile() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedPatientProfile: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> completeMemoriesTutorial() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedMemoriesTutorial: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> completeTherapyTutorial() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedTherapyTutorial: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> skipOnboarding() async {
    if (_onboardingStatus == null) return;

    _onboardingStatus = _onboardingStatus!.copyWith(
      hasCompletedWelcome: true,
      hasCompletedSidebarTutorial: true,
      hasCompletedPatientProfile: true,
      hasCompletedMemoriesTutorial: true,
      hasCompletedTherapyTutorial: true,
      lastModified: DateTime.now(),
    );
    await _saveOnboardingStatus();
    notifyListeners();
  }

  Future<void> _saveOnboardingStatus() async {
    if (_onboardingStatus == null) return;

    try {
      await _firestore
          .collection('onboarding_status')
          .doc(_onboardingStatus!.userId)
          .set(_onboardingStatus!.toJson());
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }
}
