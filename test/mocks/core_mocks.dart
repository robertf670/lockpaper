import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';

// Add other classes to mock here as needed
@GenerateMocks([
  LocalAuthentication,
  FlutterSecureStorage,
])
void main() {} // Mockito needs a main function to attach annotations 