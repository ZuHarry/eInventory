import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class DevicePingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Check if device is reachable using socket connection
  Future<bool> pingDevice(String ipAddress, {int timeoutSeconds = 10}) async {
    // Common ports to try
    final ports = [80, 443, 8080, 22, 23, 3389, 21, 25];
    
    for (final port in ports) {
      try {
        final socket = await Socket.connect(
          ipAddress,
          port,
          timeout: Duration(seconds: timeoutSeconds),
        );
        await socket.close();
        return true;
      } catch (e) {
        // Continue to next port
        continue;
      }
    }
    return false;
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
      final isOnline = await pingDevice(ipAddress);
      print('Device $deviceId ($ipAddress): ${isOnline ? 'Offline' : 'Online'}');
      return MapEntry(deviceId, isOnline);
    } catch (e) {
      print('Error pinging device $deviceId: $e');
      return MapEntry(deviceId, false);
    }
  }
  
  // Update multiple devices status in Firestore
  Future<void> _updateDevicesStatus(Map<String, bool> results) async {
    final batch = _firestore.batch();
    
    for (final entry in results.entries) {
      final deviceRef = _firestore.collection('devices').doc(entry.key);
      batch.update(deviceRef, {
        'status': entry.value ? 'Offline' : 'Online',
        'last_ping': FieldValue.serverTimestamp(),
      });
    }
    
    try {
      await batch.commit();
      print('Updated ${results.length} devices status');
    } catch (e) {
      print('Error updating devices status: $e');
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
        'status': isOnline ? 'Offline' : 'Online',
        'last_ping': FieldValue.serverTimestamp(),
      });
      
      return isOnline;
    } catch (e) {
      print('Error pinging specific device $deviceId: $e');
      return false;
    }
  }
}