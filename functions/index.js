const functions = require('firebase-functions');
const admin = require('firebase-admin');
const ping = require('ping');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Scheduled function to check device status every 2 minutes
exports.checkDeviceStatus = functions.pubsub
  .schedule('every 2 minutes')
  .timeZone('Asia/Kuala_Lumpur') // Adjust to your timezone
  .onRun(async (context) => {
    console.log('Starting device status check...');
    
    try {
      // Get all devices from Firestore
      const devicesSnapshot = await db.collection('devices').get();
      
      if (devicesSnapshot.empty) {
        console.log('No devices found');
        return null;
      }

      // Create an array of ping promises
      const pingPromises = [];
      const deviceData = [];

      devicesSnapshot.forEach(doc => {
        const device = doc.data();
        const deviceId = doc.id;
        
        if (device.ip) {
          deviceData.push({ id: deviceId, ip: device.ip, name: device.name });
          pingPromises.push(pingDevice(device.ip));
        }
      });

      // Execute all pings concurrently
      const pingResults = await Promise.all(pingPromises);

      // Update device statuses in batch
      const batch = db.batch();
      
      for (let i = 0; i < deviceData.length; i++) {
        const device = deviceData[i];
        const isOnline = pingResults[i];
        const status = isOnline ? 'Online' : 'Offline';
        
        const deviceRef = db.collection('devices').doc(device.id);
        batch.update(deviceRef, {
          status: status,
          lastChecked: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log(`${device.name} (${device.ip}): ${status}`);
      }

      // Commit all updates
      await batch.commit();
      console.log(`Updated status for ${deviceData.length} devices`);
      
    } catch (error) {
      console.error('Error checking device status:', error);
    }
    
    return null;
  });

// Helper function to ping a device
async function pingDevice(ip) {
  try {
    const result = await ping.promise.probe(ip, {
      timeout: 5, // 5 second timeout
      min_reply: 1, // At least 1 reply
      extra: ['-c', '3'] // Send 3 ping packets
    });
    
    return result.alive;
  } catch (error) {
    console.error(`Error pinging ${ip}:`, error);
    return false;
  }
}

// Manual trigger function for testing
exports.checkDeviceStatusManual = functions.https.onRequest(async (req, res) => {
  console.log('Manual device status check triggered');
  
  try {
    // Same logic as scheduled function
    const devicesSnapshot = await db.collection('devices').get();
    
    if (devicesSnapshot.empty) {
      res.json({ message: 'No devices found' });
      return;
    }

    const results = [];
    const pingPromises = [];
    const deviceData = [];

    devicesSnapshot.forEach(doc => {
      const device = doc.data();
      const deviceId = doc.id;
      
      if (device.ip) {
        deviceData.push({ id: deviceId, ip: device.ip, name: device.name });
        pingPromises.push(pingDevice(device.ip));
      }
    });

    const pingResults = await Promise.all(pingPromises);
    const batch = db.batch();
    
    for (let i = 0; i < deviceData.length; i++) {
      const device = deviceData[i];
      const isOnline = pingResults[i];
      const status = isOnline ? 'Online' : 'Offline';
      
      const deviceRef = db.collection('devices').doc(device.id);
      batch.update(deviceRef, {
        status: status,
        lastChecked: admin.firestore.FieldValue.serverTimestamp()
      });
      
      results.push({
        name: device.name,
        ip: device.ip,
        status: status
      });
    }

    await batch.commit();
    
    res.json({
      message: `Checked ${deviceData.length} devices`,
      results: results
    });
    
  } catch (error) {
    console.error('Error in manual check:', error);
    res.status(500).json({ error: error.message });
  }
});

// Function to add a device (optional helper)
exports.addDevice = functions.https.onRequest(async (req, res) => {
  try {
    const { name, ip, type, location } = req.body;
    
    if (!name || !ip) {
      res.status(400).json({ error: 'Name and IP are required' });
      return;
    }

    const deviceData = {
      name: name,
      ip: ip,
      type: type || 'PC',
      location: location || '',
      status: 'Unknown',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      lastChecked: null
    };

    const docRef = await db.collection('devices').add(deviceData);
    
    res.json({
      message: 'Device added successfully',
      id: docRef.id,
      device: deviceData
    });
    
  } catch (error) {
    console.error('Error adding device:', error);
    res.status(500).json({ error: error.message });
  }
});