import '../../../../core/errors/app_exception.dart';

String mapAuthError(Object error) {
  final raw = error is AppException ? error.message : error.toString();
  final normalized = _normalize(raw);
  final lower = normalized.toLowerCase();

  if (normalized.isEmpty) {
    return 'Something went wrong. Please try again.';
  }

  if (lower.contains('<!doctype html') ||
      lower.contains('<html') ||
      lower.contains('server error (500)')) {
    return 'Server error. Please try again in a minute.';
  }

  if (lower.contains('network error') ||
      lower.contains('cannot connect') ||
      lower.contains('connection timeout') ||
      lower.contains('request timeout')) {
    return 'Connection problem. Check internet and try again.';
  }

  if (lower.contains('invalid phone')) {
    return 'Invalid phone number. Use format +998901234567.';
  }

  if (lower.contains('phone number is missing')) {
    return 'Phone number is required. Request code again.';
  }

  if (lower.contains('invalid code')) {
    return 'Invalid verification code. Enter 6 digits.';
  }

  if (lower.contains('code expired')) {
    return 'Code expired. Request a new code.';
  }

  if (lower.contains('already exists') ||
      lower.contains('already registered') ||
      lower.contains('user with this email')) {
    return 'This email is already registered. Please sign in.';
  }

  if (lower.contains('invalid demo credentials') ||
      lower.contains('no active account') ||
      lower.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }

  return normalized;
}

String _normalize(String message) {
  final noRequestSuffix = message.replaceAll(
    RegExp(r'\s*\(request:\s*https?:\/\/[^)]*\)\s*$', caseSensitive: false),
    '',
  );
  return noRequestSuffix.trim();
}

