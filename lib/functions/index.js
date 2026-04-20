const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// This function runs automatically EVERY TIME your ESP32 pushes a new reading to 'telemetry'
exports.processTelemetry = functions.firestore
  .document("telemetry/{docId}")
  .onCreate(async (snap, context) => {
    const newData = snap.data();

    // Safety check: ensure we have the required data
    if (!newData.containerId || newData.temperature === undefined) {
      console.warn("Invalid telemetry data received, skipping.");
      return null;
    }

    const containerId = newData.containerId;
    const currentTemp = newData.temperature;
    // Fallback to 50% if the ESP32 forgot to send humidity
    const currentHumidity = newData.humidity || 50.0;
    const isDoorOpen = newData.doorOpen || false;

    let newStatus = "Safe";
    let alertMessages = [];

    try {
      // --- 1. RAPID FLUCTUATION LOGIC ---
      const previousReadingSnapshot = await db.collection('telemetry')
        .where('containerId', '==', containerId)
        .orderBy('timestamp', 'desc')
        .offset(1) // Skip the reading that just triggered this function
        .limit(1)
        .get();

      if (!previousReadingSnapshot.empty) {
        const previousTemp = previousReadingSnapshot.docs[0].data().temperature;
        const tempDifference = Math.abs(currentTemp - previousTemp);

        // RULE: If temperature fluctuates by 2.0°C or more suddenly
        if (tempDifference >= 2.0) {
          newStatus = "Warning";
          alertMessages.push(`Rapid fluctuation: ${tempDifference.toFixed(1)}°C jump detected.`);
        }
      }

      // --- 2. THRESHOLD RULES (Temp & Humidity) ---
      if (currentTemp > 8.0) {
        newStatus = "Critical";
        alertMessages.push(`Temp critical: ${currentTemp.toFixed(1)}°C exceeds 8.0°C maximum.`);
      } else if (currentTemp > 6.0 && newStatus !== "Critical") {
        newStatus = "Warning";
        alertMessages.push(`Temp warning: ${currentTemp.toFixed(1)}°C is elevated.`);
      }

      // Warn if humidity gets dangerously high (e.g., condensation risk)
      if (currentHumidity > 80.0 && newStatus !== "Critical") {
        newStatus = "Warning";
        alertMessages.push(`Humidity warning: ${currentHumidity.toFixed(0)}% is very high.`);
      }

      // --- 3. HARDWARE SENSOR RULES ---
      if (isDoorOpen) {
        newStatus = "Critical"; // A breached door is an immediate critical failure
        alertMessages.push("Alert: Magnetic door seal broken!");
      }

      // --- 4. ALERTS & PUSH NOTIFICATIONS ---
      if (alertMessages.length > 0) {
        const fullMessage = alertMessages.join(" | ");
        console.log(`[ALERT] Container ${containerId} ->`, fullMessage);

        // Save the alert to the database for the Alerts Screen history
        await db.collection('alerts').add({
            title: `Alert: ${containerId}`,
            description: fullMessage,
            type: newStatus === 'Critical' ? 'critical' : 'warning',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // Send the Push Notification to the phone!
        const payload = {
          notification: {
            title: `🚨 Cold Chain Alert: ${containerId}`,
            body: fullMessage,
          },
          topic: 'alerts'
        };

        try {
          await admin.messaging().send(payload);
          console.log("Push notification sent successfully!");
        } catch (error) {
          console.error("Error sending push notification:", error);
        }
      }

// --- 5. UPDATE DASHBOARD ---
      await db.collection("containers").doc(containerId).set({
        temperature: currentTemp,
        humidity: currentHumidity,
        status: newStatus,
        // If the ESP32 sends a new city name or coordinate string, update it here!
        location: newData.currentCity || newData.location || "In Transit",
        latitude: newData.latitude || 0.0,
        longitude: newData.longitude || 0.0,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });