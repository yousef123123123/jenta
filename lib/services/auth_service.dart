import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthResult { success, invalidKey, expired, wrongDevice, inactive, error }

/// Holds license data returned on successful auth.
class LicenseData {
  final String name;
  final String licenseKey;
  final int durationMonths;
  final DateTime expiresAt;

  LicenseData({
    required this.name,
    required this.licenseKey,
    required this.durationMonths,
    required this.expiresAt,
  });
}

/// Result of a license key validation attempt.
class AuthResponse {
  final AuthResult result;
  final LicenseData? licenseData;

  AuthResponse({required this.result, this.licenseData});
}

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Validates a license key and binds it to the device.
  /// Returns an [AuthResponse] with the result and license data on success.
  static Future<AuthResponse> validateLicenseKey({
    required String licenseKey,
    required String deviceId,
  }) async {
    try {
      // 1. Look up the key in the database
      final response = await _supabase
          .from('license_keys')
          .select()
          .eq('license_key', licenseKey.trim().toUpperCase())
          .maybeSingle();

      // Key not found
      if (response == null) {
        return AuthResponse(result: AuthResult.invalidKey);
      }

      // 2. Check if key is active
      if (response['is_active'] != true) {
        return AuthResponse(result: AuthResult.inactive);
      }

      // 3. Check expiration
      final expiresAt = DateTime.parse(response['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        return AuthResponse(result: AuthResult.expired);
      }

      // 4. Check device binding
      final boundDeviceId = response['device_id'] as String?;

      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        // First time — bind this device to the key
        await _supabase
            .from('license_keys')
            .update({'device_id': deviceId})
            .eq('id', response['id']);

        debugPrint('Device bound: $deviceId');
      } else if (boundDeviceId != deviceId) {
        // Different device — reject
        return AuthResponse(result: AuthResult.wrongDevice);
      }

      // 5. Build license data
      final licenseData = LicenseData(
        name: response['name'] ?? 'User',
        licenseKey: response['license_key'],
        durationMonths: response['duration_months'] ?? 0,
        expiresAt: expiresAt,
      );

      return AuthResponse(result: AuthResult.success, licenseData: licenseData);
    } catch (e) {
      debugPrint('Auth error: $e');
      return AuthResponse(result: AuthResult.error);
    }
  }

  /// Returns a user-friendly error message for each result.
  static String getErrorMessage(AuthResult result) {
    switch (result) {
      case AuthResult.invalidKey:
        return 'Invalid license key. Please check and try again.';
      case AuthResult.expired:
        return 'This license key has expired.';
      case AuthResult.wrongDevice:
        return 'This key is already registered to another device. You cannot log in with this device.';
      case AuthResult.inactive:
        return 'This license key has been deactivated.';
      case AuthResult.error:
        return 'An error occurred. Please check your internet connection and try again.';
      case AuthResult.success:
        return '';
    }
  }
}
