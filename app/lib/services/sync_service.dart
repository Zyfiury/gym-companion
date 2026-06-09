import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_config.dart';

/// Offline queue — syncs to OpenClaw gateway when connectivity returns.
class SyncService {
  static const _queueKey = 'gymapp_offline_queue_v1';
  static bool _listening = false;

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static Future<void> startListening() async {
    if (_listening) return;
    _listening = true;
    Connectivity().onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        await flushQueue();
      }
    });
  }

  static Future<void> enqueue(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    raw.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, raw);
  }

  static Future<void> flushQueue() async {
    if (!BackendConfig.hasOpenClaw) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    if (raw.isEmpty) return;

    final remaining = <String>[];
    for (final itemRaw in raw) {
      try {
        final item = jsonDecode(itemRaw) as Map<String, dynamic>;
        final base = BackendConfig.openclawHttpBase;
        if (base == null) {
          remaining.add(itemRaw);
          continue;
        }
        if (item['type'] == 'CHAT_COMMAND') {
          final payload = item['payload'] as Map<String, dynamic>;
          final res = await http.post(
            Uri.parse('$base/api/message'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'CHAT_COMMAND: ${jsonEncode(payload)}',
              'userId': payload['userId'],
            }),
          );
          if (res.statusCode != 200) remaining.add(itemRaw);
        } else if (item['type'] == 'USER_MD_SYNC') {
          final payload = item['payload'] as Map<String, dynamic>;
          final res = await http.post(
            Uri.parse('$base/api/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': 'USER_MD_SYNC',
              'userId': payload['userId'],
              'markdown': payload['markdown'],
            }),
          );
          if (res.statusCode != 200) remaining.add(itemRaw);
        } else {
          remaining.add(itemRaw);
        }
      } catch (e) {
        debugPrint('Sync flush error: $e');
        remaining.add(itemRaw);
      }
    }
    await prefs.setStringList(_queueKey, remaining);
  }

}
