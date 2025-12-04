import 'package:flutter_dotenv/flutter_dotenv.dart';

String get API_BASE_URL => dotenv.env['API_BASE_URL'] ?? 'https://api.local';
const int API_TIMEOUT_SECONDS = 30;
