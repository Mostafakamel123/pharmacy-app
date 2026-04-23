import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ConnectivityHelper.instance.connectionStatusStream;
});

/// Simple boolean provider for current connection status
final isNetworkConnectedProvider = FutureProvider<bool>((ref) async {
  return ConnectivityHelper.instance.isConnected();
});

/// Network connectivity helper
/// 
/// Provides methods to check and monitor network connectivity.
class ConnectivityHelper {
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();

  late final Connectivity _connectivity;
  late final StreamController<bool> _connectionStatusController;

  factory ConnectivityHelper() {
    return _instance;
  }

  ConnectivityHelper._internal() {
    _connectivity = Connectivity();
    _connectionStatusController = StreamController<bool>.broadcast();
    _initializeConnectivityListener();
  }

  static ConnectivityHelper get instance => _instance;

  /// Stream of connectivity status changes
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Initialize connectivity listener
  void _initializeConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = _isConnected(result);
      _connectionStatusController.add(isConnected);
    });
  }

  /// Check if device is currently connected to network
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnected(result);
    } catch (e) {
      // If there's an error checking connectivity, assume connected
      return true;
    }
  }

  /// Check current connectivity type
  Future<ConnectivityResult> getConnectivityType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.isEmpty) {
        return ConnectivityResult.none;
      }
      return result.first;
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Check if connected via WiFi
  Future<bool> isConnectedViaWifi() async {
    final connectivityType = await getConnectivityType();
    return connectivityType == ConnectivityResult.wifi;
  }

  /// Check if connected via Mobile data
  Future<bool> isConnectedViaMobileData() async {
    final connectivityType = await getConnectivityType();
    return connectivityType == ConnectivityResult.mobile;
  }

  /// Check if connected via Ethernet
  Future<bool> isConnectedViaEthernet() async {
    final connectivityType = await getConnectivityType();
    return connectivityType == ConnectivityResult.ethernet;
  }

  /// Get human-readable connectivity status
  Future<String> getConnectivityStatus() async {
    final connectivityType = await getConnectivityType();
    
    switch (connectivityType) {
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.satellite:
        return 'Satellite';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  /// Helper method to check if connection result indicates connected state
  bool _isConnected(List<ConnectivityResult> result) {
    if (result.isEmpty) {
      return false;
    }
    
    return !result.contains(ConnectivityResult.none);
  }

  /// Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}
