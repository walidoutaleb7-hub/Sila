import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _sub;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !_hasNone(result);
      notifyListeners();
    } catch (_) {}

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !_hasNone(results);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _hasNone(List<ConnectivityResult> results) {
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final connectivityService = ConnectivityService();