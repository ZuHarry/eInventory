import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DevicePingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Connectivity _connectivity = Connectivity();
  
  Future<bool> _hasNetworkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  
  // Check if device is reachable using socket connection
  Future<bool> pingDevice(String ipAddress, {int timeoutSeconds = 5}) async {
  try {
    final ping = Ping(ipAddress, count: 1, timeout: timeoutSeconds);
    
    await for (final result in ping.stream) {
      if (result.error == null && result.response != null) {
        return true;
      }
    }
    return false;
  } catch (e) {
    print('Ping error for $ipAddress: $e');
    return false;
  }
}
  
  // Alternative method using InternetAddress lookup
  Future<bool> checkDeviceReachability(String ipAddress) async {
    try {
      final result = await InternetAddress.lookup(ipAddress)
          .timeout(Duration(seconds: 10));
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Ping all devices from Firestore and update their status
  Future<Map<String, bool>> pingAllDevices() async {
    
    // Check network first
    if (!await _hasNetworkConnection()) {
      print('No network connection, skipping ping');
      return {};
    }

    Map<String, bool> results = {};
    
    try {
      // Get all devices from Firestore
      final devicesSnapshot = await _firestore.collection('devices').get();
      
      // Create a list of ping futures
      List<Future<MapEntry<String, bool>>> pingTasks = [];
      
      for (var doc in devicesSnapshot.docs) {
        final data = doc.data();
        final ipAddress = data['ip'] as String?;
        
        if (ipAddress != null && ipAddress.isNotEmpty) {
          pingTasks.add(_pingDeviceWithId(doc.id, ipAddress));
        }
      }
      
      // Execute all pings concurrently
      final pingResults = await Future.wait(pingTasks);
      
      // Convert results to map
      for (final result in pingResults) {
        results[result.key] = result.value;
      }
      
      // Update all devices in Firestore
      await _updateDevicesStatus(results);
      
    } catch (e) {
      print('Error pinging devices: $e');
    }
    
    return results;
  }
  
  // Helper method to ping a device and return result with ID
  Future<MapEntry<String, bool>> _pingDeviceWithId(String deviceId, String ipAddress) async {
  try {
    // Validate IP address format
    if (!_isValidIpAddress(ipAddress)) {
      print('Invalid IP address for device $deviceId: $ipAddress');
      return MapEntry(deviceId, false);
    }
    
    final isOnline = await pingDevice(ipAddress, timeoutSeconds: 3);
    print('Device $deviceId ($ipAddress): ${isOnline ? 'Online' : 'Offline'}');
    return MapEntry(deviceId, isOnline);
  } catch (e) {
    print('Error pinging device $deviceId: $e');
    return MapEntry(deviceId, false);
  }
}

bool _isValidIpAddress(String ip) {
  final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
  if (!ipRegex.hasMatch(ip)) return false;
  
  final parts = ip.split('.');
  return parts.every((part) => int.parse(part) <= 255);
}
  
  // Update multiple devices status in Firestore
  Future<void> _updateDevicesStatus(Map<String, bool> results) async {
  final batch = _firestore.batch();
  int updateCount = 0;
  
  for (final entry in results.entries) {
    final deviceRef = _firestore.collection('devices').doc(entry.key);
    
    // Only update if status actually changed
    final currentDoc = await deviceRef.get();
    if (currentDoc.exists) {
      final currentStatus = currentDoc.data()?['status'];
      final newStatus = entry.value ? 'Online' : 'Offline';
      
      // Skip update if status hasn't changed
      if (currentStatus == newStatus) {
        continue;
      }
    }
    
    batch.update(deviceRef, {
      'status': entry.value ? 'Online' : 'Offline',
      'last_ping': FieldValue.serverTimestamp(),
    });
    updateCount++;
  }
  
  if (updateCount > 0) {
    try {
      await batch.commit();
      print('Updated $updateCount devices status (${results.length - updateCount} unchanged)');
    } catch (e) {
      print('Error updating devices status: $e');
    }
  } else {
    print('No status changes detected, skipping Firestore update');
  }
}
  
  // Stream devices with real-time updates
  Stream<List<Map<String, dynamic>>> getDevicesStream() {
    return _firestore.collection('devices').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList(),
    );
  }
  
  // Ping devices periodically
  Timer? _pingTimer;
  
  void startPeriodicPing({Duration interval = const Duration(seconds: 10)}) {
    _pingTimer?.cancel();
    
    // Initial ping
    pingAllDevices();
    
    // Set up periodic pinging
    _pingTimer = Timer.periodic(interval, (timer) {
      pingAllDevices();
    });
  }
  
  void stopPeriodicPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  // Manual ping for a specific device
  Future<bool> pingSpecificDevice(String deviceId) async {
    try {
      final doc = await _firestore.collection('devices').doc(deviceId).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final ipAddress = data['ip'] as String?;
      
      if (ipAddress == null || ipAddress.isEmpty) return false;
      
      final isOnline = await pingDevice(ipAddress);
      
      // Update this specific device
      await _firestore.collection('devices').doc(deviceId).update({
        'status': isOnline ? 'Online' : 'Offline',
        'last_ping': FieldValue.serverTimestamp(),
      });
      
      return isOnline;
    } catch (e) {
      print('Error pinging specific device $deviceId: $e');
      return false;
    }
  }
}