import 'package:firebase_auth/firebase_auth.dart';

enum PasswordStrength { weak, fair, strong }

class PasswordRequirements {
  final bool minLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;

  const PasswordRequirements({
    required this.minLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  bool get allMet => minLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;

  static PasswordRequirements evaluate(String password) {
    return PasswordRequirements(
      minLength: password.length >= AuthValidator.minPasswordLength,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasNumber: RegExp(r'[0-9]').hasMatch(password),
      hasSpecial: RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(password),
    );
  }
}

class AuthValidator {
  static const minPasswordLength = 8;
  static const maxDisplayNameLength = 30;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  static String? emailError(String email, {bool required = true}) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return required ? 'Enter your email address' : null;
    if (!trimmed.contains('@')) return 'Email must include @';
    if (!isValidEmail(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static PasswordStrength passwordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    final req = PasswordRequirements.evaluate(password);
    final score = [
      req.minLength,
      req.hasUppercase,
      req.hasLowercase,
      req.hasNumber,
      req.hasSpecial,
    ].where((v) => v).length;
    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.fair;
    return PasswordStrength.weak;
  }

  static String? passwordSignUpError(String password) {
    if (password.isEmpty) return 'Create a password';
    final req = PasswordRequirements.evaluate(password);
    if (!req.allMet) return 'Password does not meet all requirements';
    return null;
  }

  static String? confirmPasswordError(String password, String confirm) {
    if (confirm.isEmpty) return 'Confirm your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  static String? displayNameError(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a display name';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > maxDisplayNameLength) {
      return 'Name must be $maxDisplayNameLength characters or fewer';
    }
    return null;
  }

  static String? loginPasswordError(String password) {
    if (password.isEmpty) return 'Enter your password';
    return null;
  }

  static bool canLogin({required String email, required String password}) {
    return emailError(email) == null && loginPasswordError(password) == null;
  }

  static bool canSignUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    required bool termsAccepted,
  }) {
    return emailError(email) == null &&
        passwordSignUpError(password) == null &&
        confirmPasswordError(password, confirmPassword) == null &&
        displayNameError(displayName) == null &&
        termsAccepted;
  }

  /// Sign-up rules enforced on local auth backend.
  static void assertSignUpPassword(String password) {
    final err = passwordSignUpError(password);
    if (err != null) throw Exception(err);
  }

  static String friendlyAuthError(Object error) {
    if (error is FirebaseAuthException) {
      return _firebaseCodeMessage(error.code, error.message);
    }
    final raw = error.toString();
    if (raw.contains('cancelled')) return '';
    final codeMatch = RegExp(r'\[firebase_auth/([^\]]+)\]').firstMatch(raw);
    if (codeMatch != null) {
      return _firebaseCodeMessage(codeMatch.group(1)!, raw);
    }
    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('[firebase_auth/cancelled] ', '')
        .trim();
  }

  static String _firebaseCodeMessage(String code, String? fallback) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Password is too weak — follow the requirements above';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'user-not-found':
        return 'No account found with this email';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts — try again in a few minutes';
      case 'network-request-failed':
        return 'Network error — check your connection';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app';
      case 'cancelled':
        return '';
      default:
        final msg = fallback?.replaceFirst('Exception: ', '').trim();
        if (msg != null && msg.isNotEmpty && !msg.startsWith('[')) return msg;
        return 'Something went wrong — please try again';
    }
  }
}
