import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseBaseUrlService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> fetchBaseUrl() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('config').doc('base_url').get();

      if (snapshot.exists) {
        return snapshot['url'] as String;
      } else {
        throw Exception("Base URL not found in Firebase");
      }
    } catch (e) {
      throw Exception('Failed to fetch base URL from Firebase: $e');
    }
  }
}
