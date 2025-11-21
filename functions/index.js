const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { Configuration, OpenAIApi } = require('openai');

admin.initializeApp();

// Initialize OpenAI
const configuration = new Configuration({
  apiKey: functions.config().openai?.key || process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

/**
 * Cloud Function to analyze clothing image using AI
 * Triggered via HTTPS call from the app
 */
exports.analyzeClothingImage = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to analyze images.'
    );
  }

  const { imageUrl } = data;

  if (!imageUrl) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Image URL is required.'
    );
  }

  try {
    // Call OpenAI Vision API
    const response = await openai.createChatCompletion({
      model: 'gpt-4-vision-preview',
      messages: [
        {
          role: 'system',
          content: `You are a fashion expert AI. Analyze the clothing item in the image and provide:
1. Category (Tops, Bottoms, Dresses, Outerwear, Shoes, Accessories, Traditional)
2. Subcategory (e.g., T-Shirt, Jeans, etc.)
3. Dominant colors (list up to 3)
4. Pattern (Solid, Striped, Checkered, Floral, Polka Dots, Abstract, Printed)
5. Style tags (e.g., casual, formal, sporty)
6. Suitable occasions

Respond in JSON format.`
        },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: imageUrl }
            },
            { type: 'text', text: 'Analyze this clothing item.' }
          ]
        }
      ],
      max_tokens: 500,
    });

    const analysisText = response.data.choices[0].message.content;
    const analysis = JSON.parse(analysisText);

    return {
      success: true,
      analysis: analysis,
    };
  } catch (error) {
    console.error('Error analyzing image:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to analyze image',
      error.message
    );
  }
});

/**
 * Generate outfit recommendations using AI
 */
exports.generateOutfitRecommendations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const { wardrobeItems, context: requestContext } = data;

  try {
    const prompt = `As a professional fashion stylist, suggest outfit combinations from these wardrobe items:

Items: ${JSON.stringify(wardrobeItems)}

Context:
- Occasion: ${requestContext.occasion || 'any'}
- Weather: ${requestContext.weather || 'any'} (${requestContext.temperature || 'comfortable'}°C)
- Mood: ${requestContext.mood || 'confident'}

Provide 3-5 outfit recommendations with explanations.`;

    const response = await openai.createChatCompletion({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'You are a friendly, expert fashion stylist.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 1000,
      temperature: 0.7,
    });

    const recommendations = response.data.choices[0].message.content;

    return {
      success: true,
      recommendations: recommendations,
    };
  } catch (error) {
    console.error('Error generating recommendations:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate recommendations',
      error.message
    );
  }
});

/**
 * Parse natural language styling request
 */
exports.parseStyleRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const { userPrompt } = data;

  try {
    const systemPrompt = `Extract structured information from this fashion request.
Identify: occasion, mood, weather conditions, time of day, specific preferences.
Respond in JSON format with keys: occasion, mood, weather, timeOfDay, preferences`;

    const response = await openai.createChatCompletion({
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 200,
    });

    const parsedContext = JSON.parse(response.data.choices[0].message.content);

    return {
      success: true,
      context: parsedContext,
    };
  } catch (error) {
    console.error('Error parsing request:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to parse request',
      error.message
    );
  }
});

/**
 * Trigger to update user statistics when clothing items are added
 */
exports.onClothingItemCreated = functions.firestore
  .document('clothing_items/{itemId}')
  .onCreate(async (snap, context) => {
    const item = snap.data();
    const userId = item.userId;

    // Update user statistics
    const userRef = admin.firestore().collection('users').doc(userId);

    await userRef.update({
      'stats.totalItems': admin.firestore.FieldValue.increment(1),
      'stats.lastItemAdded': admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * Cleanup function when user deletes account
 */
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  const batch = admin.firestore().batch();

  // Delete user data
  const userRef = admin.firestore().collection('users').doc(userId);
  batch.delete(userRef);

  // Delete all clothing items
  const itemsSnapshot = await admin.firestore()
    .collection('clothing_items')
    .where('userId', '==', userId)
    .get();

  itemsSnapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  // Delete all outfits
  const outfitsSnapshot = await admin.firestore()
    .collection('outfits')
    .where('userId', '==', userId)
    .get();

  outfitsSnapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  // Delete recommendation logs
  const logsSnapshot = await admin.firestore()
    .collection('recommendation_logs')
    .where('userId', '==', userId)
    .get();

  logsSnapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  console.log(`Deleted all data for user: ${userId}`);
  return null;
});

/**
 * Scheduled function to send daily outfit recommendations
 * Run every morning at 7 AM
 */
exports.sendDailyRecommendations = functions.pubsub
  .schedule('0 7 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    // Get all users who have enabled notifications
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('notifications.dailyRecommendations', '==', true)
      .get();

    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;

      // Get user's wardrobe
      const wardrobeSnapshot = await admin.firestore()
        .collection('clothing_items')
        .where('userId', '==', userId)
        .limit(50)
        .get();

      if (wardrobeSnapshot.empty) return;

      // Generate recommendations (simplified version)
      // In production, call the AI service

      console.log(`Generated daily recommendations for user: ${userId}`);
    });

    await Promise.all(promises);

    console.log('Daily recommendations sent');
    return null;
  });
