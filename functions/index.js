const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "Authentication required");
  }

  const {receiverId, title, message} = data;

  if (!receiverId || !title || !message) {
    throw new functions.https.HttpsError(
        "invalid-argument", "Missing required fields");
  }

  const userDoc = await admin.firestore()
      .collection("users")
      .doc(receiverId)
      .get();

  const userData = userDoc.data();
  const tokens = (userData && userData.fcmTokens) || [];

  if (tokens.length === 0) {
    return {success: false, message: "No devices registered"};
  }

  const payload = {
    notification: {
      title: title,
      body: message,
    },
    data: {
      senderId: context.auth.uid,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "chat_message",
    },
  };

  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);

    // Modified token cleanup code
    const invalidTokens = response.results
        .map((result, index) => result.error ? tokens[index] : null)
        .filter(Boolean);

    if (invalidTokens.length > 0) {
      await admin.firestore()
          .collection("users")
          .doc(receiverId)
          .update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(invalidTokens[0]),
          });
    }

    return {success: true};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
        "internal", "Notification failed to send");
  }
});
