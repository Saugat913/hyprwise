import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:finance_tracker/core/config/app_config.dart';

class AiFunctionCall {
  final String name;
  final Map<String, dynamic> args;
  const AiFunctionCall({required this.name, required this.args});

  factory AiFunctionCall.fromJson(Map<String, dynamic> json) {
    return AiFunctionCall(
      name: json['name'] as String? ?? '',
      args: (json['args'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class AiChatResult {
  final String? content;
  final List<AiFunctionCall> functionCalls;
  final bool isPro;
  const AiChatResult({this.content, this.functionCalls = const [], this.isPro = false});
}

/// Client for connecting to the Hyprwise Hono Backend Server.
/// Automatically resolves between ADB reverse (127.0.0.1:3000),
/// Android Emulator (10.0.2.2:3000), and Wi-Fi LAN (192.168.100.96:3000).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Potential host endpoints in order of priority (configurable via .env / --dart-define)
  static List<String> get _candidateHosts => [
    if (AppConfig.serverUrl.isNotEmpty) AppConfig.serverUrl,
    'http://127.0.0.1:3000',      // Localhost / ADB reverse proxy
    'http://10.0.2.2:3000',        // Android emulator loopback alias
    'http://192.168.100.96:3000',  // Local Wi-Fi host IP
  ];

  String? _resolvedBaseUrl;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Discovers the active server URL by pinging /health
  Future<String?> getBaseUrl({bool forceRefresh = false}) async {
    if (!forceRefresh && _resolvedBaseUrl != null) {
      return _resolvedBaseUrl;
    }

    for (final host in _candidateHosts) {
      try {
        final res = await http
            .get(Uri.parse('$host/health'))
            .timeout(const Duration(milliseconds: 2500));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'ok') {
            _resolvedBaseUrl = host;
            debugPrint('Connected to Tilvane server at $host');
            return host;
          }
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return _resolvedBaseUrl ?? _candidateHosts.first;
  }

  /// Pings server health
  Future<bool> checkHealth() async {
    try {
      final host = await getBaseUrl();
      if (host == null) return false;
      final res = await http
          .get(Uri.parse('$host/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate with Firebase on server
  Future<Map<String, dynamic>?> authenticateFirebase({
    required String uid,
    String? idToken,
    String? email,
    String? displayName,
    String? photoUrl,
    String? provider,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/auth/firebase'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'idToken': idToken,
              'email': email,
              'displayName': displayName,
              'photoUrl': photoUrl,
              'provider': provider,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['token'] != null) {
          setAuthToken(body['token'] as String);
        }
        return body;
      }
    } catch (e) {
      debugPrint('Error authenticating with Firebase on server: $e');
    }
    return null;
  }

  /// Authenticate with Google on server
  Future<Map<String, dynamic>?> authenticateGoogle({
    required String email,
    String? displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/auth/google'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'displayName': displayName,
              'photoUrl': photoUrl,
              'idToken': idToken,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['token'] != null) {
          setAuthToken(body['token'] as String);
        }
        return body;
      }
    } catch (e) {
      debugPrint('Error authenticating with Google on server: $e');
    }
    return null;
  }

  /// Authenticate with Apple on server
  Future<Map<String, dynamic>?> authenticateApple({
    required String email,
    String? fullName,
    String? identityToken,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/auth/apple'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'fullName': fullName,
              'identityToken': identityToken,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['token'] != null) {
          setAuthToken(body['token'] as String);
        }
        return body;
      }
    } catch (e) {
      debugPrint('Error authenticating with Apple on server: $e');
    }
    return null;
  }

  /// Push local SQLite data snapshot to cloud
  Future<Map<String, dynamic>?> pushSync(Map<String, dynamic> data) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/sync/push'),
            headers: _headers,
            body: jsonEncode({
              'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
              'data': data,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error pushing sync data: $e');
    }
    return null;
  }

  /// Pull latest cloud snapshot for this account
  Future<Map<String, dynamic>?> pullSync() async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .get(
            Uri.parse('$host/api/sync/pull'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error pulling sync data: $e');
    }
    return null;
  }

  /// Check sync status
  Future<Map<String, dynamic>?> syncStatus() async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .get(
            Uri.parse('$host/api/sync/status'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Send query to Gemini AI chat gateway with full MCP function calling support
  Future<AiChatResult?> chatWithAiDetailed(
    String message, {
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    dynamic context,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/ai/chat'),
            headers: _headers,
            body: jsonEncode({
              'messages': [
                {
                  'role': 'user',
                  'content': message,
                  if (imageBase64 != null) 'imageBase64': imageBase64,
                  if (imageMimeType != null) 'imageMimeType': imageMimeType,
                }
              ],
              if (systemInstruction != null) 'systemInstruction': systemInstruction,
              if (tools != null) 'tools': tools,
              if (context != null) 'context': context,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final rawCalls = body['functionCalls'] as List<dynamic>? ?? [];
        final calls = rawCalls
            .map((c) => AiFunctionCall.fromJson(c as Map<String, dynamic>))
            .toList();
        return AiChatResult(
          content: body['content'] as String?,
          functionCalls: calls,
          isPro: body['isPro'] as bool? ?? false,
        );
      } else if (res.statusCode == 403) {
        final body = jsonDecode(res.body);
        return AiChatResult(
          content: body['message'] as String? ?? 'This feature requires Hyprwise Pro.',
          isPro: false,
        );
      }
    } catch (e) {
      debugPrint('AI Chat gateway error: $e');
    }
    return null;
  }

  /// Send query to Gemini AI chat gateway (legacy convenience wrapper)
  Future<String?> chatWithAi(
    String message, {
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    final result = await chatWithAiDetailed(
      message,
      systemInstruction: systemInstruction,
      tools: tools,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
    );
    return result?.content;
  }

  /// Verify subscription with backend and RevenueCat
  Future<Map<String, dynamic>?> verifySubscription({
    required String appUserId,
    required String planId,
    String? purchaseToken,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/subscription/verify'),
            headers: _headers,
            body: jsonEncode({
              'appUserId': appUserId,
              'planId': planId,
              'purchaseToken': purchaseToken,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error verifying subscription: $e');
    }
    return null;
  }

  /// Check subscription status on backend
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .get(
            Uri.parse('$host/api/subscription/status'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Server-side export CSV (Pro restricted)
  Future<Map<String, dynamic>?> exportCsv(Map<String, dynamic> data) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .post(
            Uri.parse('$host/api/export/csv'),
            headers: _headers,
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error exporting CSV from server: $e');
    }
    return null;
  }

  /// Get live forex rates from server (Pro restricted)
  Future<List<Map<String, dynamic>>?> getForexRates() async {
    try {
      final host = await getBaseUrl();
      if (host == null) return null;

      final res = await http
          .get(
            Uri.parse('$host/api/currency/rates'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = body['rates'] as List<dynamic>?;
        if (rates != null) {
          return rates.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Error fetching forex rates from server: $e');
    }
    return null;
  }

  /// Delete account and remote cloud data
  Future<bool> deleteAccount({String? userId, String? email, String? reason}) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return false;

      final res = await http
          .post(
            Uri.parse('$host/api/account/delete'),
            headers: _headers,
            body: jsonEncode({
              if (userId != null) 'userId': userId,
              if (email != null) 'email': email,
              if (reason != null) 'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 6));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error requesting account deletion: $e');
      return false;
    }
  }

  /// Sends a telemetry, interaction, or exception event to the server
  Future<bool> sendTelemetryEvent({
    required String eventType,
    required String eventName,
    dynamic details,
    String? deviceInfo,
    String? appVersion,
    String? userId,
  }) async {
    try {
      final host = await getBaseUrl();
      if (host == null) return false;

      final res = await http
          .post(
            Uri.parse('$host/api/telemetry/event'),
            headers: _headers,
            body: jsonEncode({
              'eventType': eventType,
              'eventName': eventName,
              if (details != null) 'details': details,
              if (deviceInfo != null) 'deviceInfo': deviceInfo,
              if (appVersion != null) 'appVersion': appVersion,
              if (userId != null) 'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 3));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
