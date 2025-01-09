import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get webClientID => dotenv.env['WEB_CLIENT_ID'] ?? '';
  static String get iosClientID => dotenv.env['IOS_CLIENT_ID'] ?? '';
  static String get baseAPIUrl => dotenv.env['API_BASE_URL'] ?? '';
}