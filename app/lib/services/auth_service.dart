import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_validator.dart';

class Account {
  final String userId;
  final String email;
  final String passwordHash;
  final String displayName;
  final String createdAt;

  Account({
    required this.userId,
    required this.email,
    required this.passwordHash,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'passwordHash': passwordHash,
        'displayName': displayName,
        'createdAt': createdAt,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        userId: j['userId'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        displayName: j['displayName'] as String,
        createdAt: j['createdAt'] as String,
      );
}

/// Pre-seeded test accounts — see TEST_ACCOUNTS.md
class TestAccounts {
  static const testEmail = 'test@gym.app';
  static const testPassword = 'test123';
  static const demoEmail = 'demo@gym.app';
  static const demoPassword = 'demo123';
  static const alexEmail = 'alex@gym.app';
  static const alexPassword = 'alex123';
}

class AuthService {
  static const _accountsKey = 'gymapp_accounts';
  static const _sessionKey = 'gymapp_session';
  static const _seededKey = 'gymapp_accounts_seeded';

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> seedTestAccountsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    final accounts = <Account>[
      Account(
        userId: 'user_test_001',
        email: TestAccounts.testEmail,
        passwordHash: hashPassword(TestAccounts.testPassword),
        displayName: 'Test User',
        createdAt: DateTime.now().toIso8601String(),
      ),
      Account(
        userId: 'user_demo_002',
        email: TestAccounts.demoEmail,
        passwordHash: hashPassword(TestAccounts.demoPassword),
        displayName: 'Demo User',
        createdAt: DateTime.now().toIso8601String(),
      ),
      Account(
        userId: 'user_alex_003',
        email: TestAccounts.alexEmail,
        passwordHash: hashPassword(TestAccounts.alexPassword),
        displayName: 'Alex',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];

    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
    await prefs.setBool(_seededKey, true);
  }

  Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Account> signUp({required String email, required String password, required String displayName}) async {
    final normalized = AuthValidator.normalizeEmail(email);
    final emailErr = AuthValidator.emailError(email);
    if (emailErr != null) throw Exception(emailErr);
    AuthValidator.assertSignUpPassword(password);
    final nameErr = AuthValidator.displayNameError(displayName);
    if (nameErr != null) throw Exception(nameErr);
    final accounts = await getAccounts();
    if (accounts.any((a) => a.email == normalized)) throw Exception('Account already exists');

    final account = Account(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      passwordHash: hashPassword(password),
      displayName: displayName.trim().isEmpty ? normalized.split('@').first : displayName.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    accounts.add(account);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
    return account;
  }

  Future<Account> login({required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    final hash = hashPassword(password);
    final accounts = await getAccounts();
    final account = accounts.where((a) => a.email == normalized && a.passwordHash == hash).firstOrNull;
    if (account == null) throw Exception('Invalid email or password');
    return account;
  }

  Future<void> saveSession(Account account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode({
      'userId': account.userId,
      'email': account.email,
      'displayName': account.displayName,
    }));
  }

  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'userId': m['userId'] as String,
      'email': m['email'] as String,
      'displayName': m['displayName'] as String,
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
