import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  static String get webClientID => dotenv.env['WEB_CLIENT_ID'] ?? '';
  static String get iosClientID => dotenv.env['IOS_CLIENT_ID'] ?? '';
}
