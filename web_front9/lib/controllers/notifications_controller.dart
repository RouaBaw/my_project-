import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// Central GetX controller that polls the `/notifications` endpoint
/// every 30 seconds and exposes the full list + unread count to the UI.
///
/// Registered as a permanent singleton in `main.dart` so the bell widget can
/// listen to it from anywhere in the app.
class NotificationsController extends GetxController {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration _pollInterval = Duration(seconds: 30);

  final _storage = GetStorage();

  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startPolling();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startPolling() {
    _timer?.cancel();
    fetchUnreadCount();
    fetchAll();
    _timer = Timer.periodic(_pollInterval, (_) {
      fetchUnreadCount();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Map<String, String> get _headers {
    final token = _storage.read('token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        unreadCount.value = (body['unread_count'] ?? 0) as int;
        hasError.value = false;
      }
    } catch (_) {
      hasError.value = true;
    }
  }

  Future<void> fetchAll({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications?per_page=50'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        items.assignAll(data);
        unreadCount.value = (body['unread_count'] ?? unreadCount.value) as int;
        hasError.value = false;
      } else {
        hasError.value = true;
      }
    } catch (_) {
      hasError.value = true;
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        unreadCount.value =
            (body['unread_count'] ?? unreadCount.value) as int;
        final idx = items.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          final updated = Map<String, dynamic>.from(items[idx]);
          updated['read_at'] = DateTime.now().toIso8601String();
          items[idx] = updated;
        }
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        unreadCount.value = 0;
        final now = DateTime.now().toIso8601String();
        items.assignAll(items.map((n) {
          final copy = Map<String, dynamic>.from(n);
          copy['read_at'] = now;
          return copy;
        }));
      }
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/notifications/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        items.removeWhere((n) => n['id'] == id);
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        unreadCount.value =
            (body['unread_count'] ?? unreadCount.value) as int;
      }
    } catch (_) {}
  }

  /// Helpers to read the uniform data payload
  static Map<String, dynamic> dataOf(Map<String, dynamic> n) {
    final raw = n['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
