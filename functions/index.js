const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.getApiInfo = functions.https.onRequest(async (request, response) => {
  try {
    const apiKeyDoc = await admin.firestore().doc("apiKeys/api").get();
    if (!apiKeyDoc.exists) {
      return response.status(404).json({error: "API key not found"});
    }

    const apiKeyData = apiKeyDoc.data();
    return response.json({
      data: {
        apiUrl: apiKeyData.apiUrl,
        apiKey: apiKeyData.apiKey,
      },
    });
  } catch (error) {
    console.error("Error getting API info:", error);
    return response.status(500).json({error: "Server error "});
  }
});
