import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/utils/auth_validator.dart';

void main() {
  group('email', () {
    test('rejects missing @', () {
      expect(AuthValidator.emailError('notanemail'), 'Email must include @');
    });

    test('accepts valid email', () {
      expect(AuthValidator.emailError('user@example.com'), isNull);
    });

    test('normalizes email', () {
      expect(AuthValidator.normalizeEmail('  User@Mail.COM '), 'user@mail.com');
    });
  });

  group('password sign-up', () {
    test('rejects weak password', () {
      expect(AuthValidator.passwordSignUpError('short'), isNotNull);
    });

    test('accepts strong password', () {
      expect(AuthValidator.passwordSignUpError('Secure1!pass'), isNull);
    });

    test('strength increases with requirements', () {
      expect(AuthValidator.passwordStrength('a'), PasswordStrength.weak);
      expect(AuthValidator.passwordStrength('Abcdef1!'), PasswordStrength.strong);
    });
  });

  group('canSignUp', () {
    test('requires terms', () {
      expect(
        AuthValidator.canSignUp(
          email: 'a@b.com',
          password: 'Secure1!pass',
          confirmPassword: 'Secure1!pass',
          displayName: 'Omar',
          termsAccepted: false,
        ),
        isFalse,
      );
    });

    test('passes when all valid', () {
      expect(
        AuthValidator.canSignUp(
          email: 'a@b.com',
          password: 'Secure1!pass',
          confirmPassword: 'Secure1!pass',
          displayName: 'Omar',
          termsAccepted: true,
        ),
        isTrue,
      );
    });
  });

  group('friendlyAuthError', () {
    test('maps firebase weak-password code in string', () {
      final msg = AuthValidator.friendlyAuthError(Exception('[firebase_auth/weak-password] Password'));
      expect(msg, contains('too weak'));
    });
  });
}
