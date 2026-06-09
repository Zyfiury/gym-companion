import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_data.dart';
import 'backend_config.dart';
import 'sync_service.dart';

/// Bridge to OpenClaw agent gateway — sends CHAT_COMMAND payloads.
class OpenClawService {
  static Future<Map<String, dynamic>> sendChatCommand({
    required String message,
    required UserData user,
    String? displayName,
  }) async {
    final uid = user.userId;
    final payload = {
      'type': 'CHAT_COMMAND',
      'userId': uid,
      'message': message,
      'userSnapshot': {
        'name': displayName ?? 'Athlete',
        'goal': user.goal,
        'weight': user.weight,
        'height': user.height,
        'age': user.age,
        'tdee': user.tdee,
        'dailyMacrosLogged': user.dailyMacrosLogged.toJson(),
        'foodLog': user.foodLog.take(5).toList(),
        'gamification': user.gamification,
        'allergies': user.allergies,
      },
    };

    final online = await SyncService.isOnline();
    if (!online) {
      await SyncService.enqueue({'type': 'CHAT_COMMAND', 'payload': payload});
      return {'ok': true, 'queued': true};
    }

    final base = BackendConfig.openclawHttpBase;
    if (base == null) return {'ok': false, 'skipped': true};

    try {
      final res = await http
          .post(
            Uri.parse('$base/api/message'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'CHAT_COMMAND: ${jsonEncode(payload)}',
              'userId': uid,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      await SyncService.enqueue({'type': 'CHAT_COMMAND', 'payload': payload});
      return {'ok': true, 'queued': true};
    }
    return {'ok': false};
  }
}
