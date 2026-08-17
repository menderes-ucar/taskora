import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RealtimeReconnectCallback = Future<void> Function();

class RealtimeManager {
  RealtimeManager._();

  static final RealtimeManager instance = RealtimeManager._();

  StreamSubscription<AuthState>? _authSubscription;

  final Set<RealtimeReconnectCallback> _callbacks =
  <RealtimeReconnectCallback>{};

  bool _initialized = false;
  bool _reconnecting = false;
  bool _disposed = false;

  void initialize() {
    if (_initialized && !_disposed) return;

    _disposed = false;
    _initialized = true;

    _authSubscription ??= Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthState,
      onError: (Object error, StackTrace stack) {
        debugPrint('[Realtime] auth listener error: $error\n$stack');
      },
    );
  }

  void register(RealtimeReconnectCallback callback) {
    if (_disposed) {
      debugPrint(
        '[Realtime] register ignored because manager is disposed.',
      );
      return;
    }

    _callbacks.add(callback);
  }

  void unregister(RealtimeReconnectCallback callback) {
    _callbacks.remove(callback);
  }

  Future<void> _handleAuthState(AuthState authState) async {
    switch (authState.event) {
      case AuthChangeEvent.tokenRefreshed:
        debugPrint('[Realtime] JWT refreshed.');
        await _reconnectAll();
        break;

      case AuthChangeEvent.signedIn:
        debugPrint('[Realtime] User signed in.');
        await _reconnectAll();
        break;

      case AuthChangeEvent.signedOut:
        debugPrint(
          '[Realtime] User signed out. '
              'Existing feature subscriptions must be disposed by their owners.',
        );
        break;

      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.userDeleted:
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
  }

  Future<void> _reconnectAll() async {
    if (_disposed || _reconnecting) return;

    _reconnecting = true;

    try {
      final callbacks = List<RealtimeReconnectCallback>.of(_callbacks);

      for (final callback in callbacks) {
        if (_disposed) break;

        try {
          await callback();
        } catch (e, stack) {
          debugPrint(
            '[Realtime] reconnect callback failed: $e\n$stack',
          );
        }
      }
    } finally {
      _reconnecting = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _initialized = false;
    _reconnecting = false;

    final subscription = _authSubscription;
    _authSubscription = null;

    await subscription?.cancel();

    _callbacks.clear();
  }
}
