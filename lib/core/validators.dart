import 'app_config.dart';

class Validators {
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    if (AppConfig.allowedEmailDomain.isNotEmpty &&
        !value.trim().toLowerCase().endsWith('@${AppConfig.allowedEmailDomain}')) {
      return 'Use your @${AppConfig.allowedEmailDomain} email';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add at least one lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number (10-14 digits)';
    }
    return null;
  }

  static String? studentId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Student ID is required';
    if (!RegExp(AppConfig.studentIdPattern).hasMatch(value.trim())) {
      return 'Invalid Student ID (${AppConfig.studentIdHint})';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value.trim())) return 'Enter a valid price';
    return null;
  }
}
