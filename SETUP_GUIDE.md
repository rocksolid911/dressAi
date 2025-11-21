# Digital Wardrobe - Detailed Setup Guide

This guide provides step-by-step instructions to set up and run the Digital Wardrobe application.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Firebase Project Setup](#firebase-project-setup)
3. [Flutter App Configuration](#flutter-app-configuration)
4. [API Keys Configuration](#api-keys-configuration)
5. [Cloud Functions Setup](#cloud-functions-setup)
6. [Running the Application](#running-the-application)
7. [Troubleshooting](#troubleshooting)

## System Requirements

### Development Environment

- **Operating System**: Windows 10/11, macOS 10.14+, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk Space**: 10GB free space

### Software Requirements

- **Flutter SDK**: Version 3.0 or higher
  - Download from: https://flutter.dev/docs/get-started/install
- **Android Studio**: Latest version (for Android development)
  - Download from: https://developer.android.com/studio
- **Xcode**: Latest version (for iOS development, macOS only)
  - Download from Mac App Store
- **Node.js**: Version 18.x or higher
  - Download from: https://nodejs.org/
- **Firebase CLI**: Latest version
  - Install via: `npm install -g firebase-tools`
- **Git**: Latest version
  - Download from: https://git-scm.com/

### API Accounts Required

1. **Firebase Account** (free tier available)
2. **OpenWeatherMap Account** (free tier available)
3. **OpenAI Account** (paid, but with free trial credits)
4. **Google Cloud Project** (for Google Sign-In)

## Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `digital-wardrobe-app` (or your preferred name)
4. Enable/disable Google Analytics (recommended to enable)
5. Click "Create Project"

### Step 2: Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click "Get Started"
3. Enable **Email/Password** provider:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"
4. Enable **Google** provider:
   - Click on "Google"
   - Toggle "Enable" to ON
   - Enter support email
   - Click "Save"

### Step 3: Create Firestore Database

1. Go to **Build** → **Firestore Database**
2. Click "Create Database"
3. Select **Start in production mode** (we'll add rules later)
4. Choose a location (select closest to your users)
5. Click "Enable"

### Step 4: Set Up Storage

1. Go to **Build** → **Storage**
2. Click "Get Started"
3. Use default security rules for now
4. Choose same location as Firestore
5. Click "Done"

### Step 5: Upgrade to Blaze Plan (Required for Cloud Functions)

1. Go to **Project Settings** → **Usage and billing**
2. Click "Modify plan"
3. Select **Blaze (Pay as you go)** plan
4. Enter payment information
   - Note: Free tier is generous; most development won't incur costs
5. Set up budget alerts (recommended)

## Flutter App Configuration

### Step 1: Install Flutter

**macOS/Linux:**
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

**Windows:**
1. Download Flutter SDK from flutter.dev
2. Extract to C:\src\flutter
3. Add to PATH: C:\src\flutter\bin
4. Run `flutter doctor` in Command Prompt

### Step 2: Install FlutterFire CLI

```bash
# Activate FlutterFire CLI
dart pub global activate flutterfire_cli

# Add to PATH (if not already)
# macOS/Linux: Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Windows: Add to System Environment Variables
# %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### Step 3: Configure Firebase for Flutter

```bash
# Navigate to Flutter app directory
cd wordrobeAI/wardrobe_app

# Run FlutterFire configure
flutterfire configure

# Select your Firebase project
# Choose platforms: Android, iOS (or both)
# This generates firebase_options.dart automatically
```

### Step 4: Install Flutter Dependencies

```bash
cd wordrobeAI/wardrobe_app
flutter pub get
```

### Step 5: Add Google Services Files

**Android:**
1. Download `google-services.json` from Firebase Console:
   - Project Settings → General → Your apps → Android app
2. Place in `mobile_app/android/app/google-services.json`

**iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console:
   - Project Settings → General → Your apps → iOS app
2. Place in `mobile_app/ios/Runner/GoogleService-Info.plist`

## API Keys Configuration

### Step 1: OpenWeatherMap API

1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Click "Sign Up" and create an account
3. Navigate to "API keys" tab
4. Copy your default API key or create a new one
5. Store securely for later use

### Step 2: OpenAI API

1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Go to [API Keys page](https://platform.openai.com/api-keys)
4. Click "Create new secret key"
5. Name it: `digital-wardrobe-app`
6. Copy the key (you won't see it again!)
7. Store securely

### Step 3: Create .env File

```bash
cd wordrobeAI/wardrobe_app

# Copy example file
cp .env.example .env

# Edit .env file
# Replace placeholder values with your actual API keys
```

**.env File Content:**
```env
# Weather API
WEATHER_API_KEY=your_openweathermap_api_key_here
WEATHER_API_BASE_URL=https://api.openweathermap.org/data/2.5

# AI Services
OPENAI_API_KEY=your_openai_api_key_here

# Affiliate Links (configure as needed)
AFFILIATE_BASE_URL=https://myaffiliate.com/product
AMAZON_AFFILIATE_TAG=your_amazon_tag
MYNTRA_AFFILIATE_ID=your_myntra_id

# Environment
ENV=development
```

**Important:** Never commit the `.env` file to version control!

## Cloud Functions Setup

### Step 1: Install Node.js Dependencies

```bash
cd wordrobeAI/functions
npm install
```

### Step 2: Configure Cloud Functions Environment

```bash
# Set OpenAI API key for Cloud Functions
firebase functions:config:set openai.key="your_openai_api_key"

# Verify configuration
firebase functions:config:get
```

### Step 3: Deploy Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:analyzeClothingImage
```

### Step 4: Deploy Firestore and Storage Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy everything at once
firebase deploy
```

## Running the Application

### Step 1: Check Flutter Setup

```bash
flutter doctor -v

# Ensure all checkmarks are green
# Fix any issues reported
```

### Step 2: Start Emulator or Connect Device

**Android Emulator:**
```bash
# List available emulators
flutter emulators

# Start emulator
flutter emulators --launch <emulator_id>
```

**iOS Simulator:**
```bash
open -a Simulator
```

**Physical Device:**
- Enable Developer Mode on device
- Connect via USB
- Enable USB debugging (Android) or Trust Computer (iOS)

### Step 3: Run the App

```bash
cd wordrobeAI/wardrobe_app

# Run on first available device
flutter run

# Run on specific device
flutter devices  # List devices
flutter run -d <device_id>

# Run in release mode (faster, no debug tools)
flutter run --release
```

### Step 4: Verify Functionality

1. **Launch App**: Should show splash screen, then login
2. **Sign Up**: Create test account with email/password
3. **Complete Onboarding**: Set preferences
4. **Home Screen**: Should load without errors
5. **Add Item**: Try uploading a clothing photo
6. **Check Weather**: Verify weather widget appears
7. **Recommendations**: Generate outfit suggestions

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues

**Problem:** Flutter doctor shows errors

**Solution:**
```bash
# Update Flutter
flutter upgrade

# Clear cache
flutter clean
flutter pub get

# Accept Android licenses (Android only)
flutter doctor --android-licenses
```

#### 2. Firebase Connection Issues

**Problem:** App can't connect to Firebase

**Solution:**
- Verify `firebase_options.dart` exists
- Check `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) placement
- Ensure internet connectivity
- Check Firebase project status in Console

#### 3. Cloud Functions Not Working

**Problem:** AI features return errors

**Solution:**
```bash
# Check function logs
firebase functions:log

# Verify deployment
firebase deploy --only functions

# Check function configuration
firebase functions:config:get

# Test function locally
cd functions
npm run serve
```

#### 4. Environment Variables Not Loading

**Problem:** API keys not found

**Solution:**
- Verify `.env` file exists in `mobile_app/` directory
- Check `.env` file syntax (no quotes around values)
- Restart app after changing `.env`
- Check `flutter_dotenv` is properly loaded in main.dart

#### 5. Image Upload Fails

**Problem:** Cannot upload clothing photos

**Solution:**
- Check Firebase Storage rules
- Verify Storage bucket exists
- Check device permissions for camera/gallery
- Ensure sufficient storage space

#### 6. Google Sign-In Not Working

**Problem:** Google sign-in fails or crashes

**Solution:**

**Android:**
- Add SHA-1 fingerprint to Firebase Console
```bash
cd android
./gradlew signingReport
```
- Copy SHA-1 and add to Firebase Console → Project Settings → Your apps → Android app

**iOS:**
- Verify URL scheme in `Info.plist`
- Check bundle ID matches Firebase configuration

### Getting Help

1. **Check Logs:**
   ```bash
   # Flutter logs
   flutter logs

   # Firebase Functions logs
   firebase functions:log

   # Firestore debugging
   # Enable debug logging in Firebase Console
   ```

2. **Enable Debug Mode:**
   - Run with `flutter run --verbose`
   - Check for detailed error messages

3. **Resources:**
   - [Flutter Documentation](https://flutter.dev/docs)
   - [Firebase Documentation](https://firebase.google.com/docs)
   - [FlutterFire Documentation](https://firebase.flutter.dev/)

## Next Steps

After successful setup:

1. **Customize the App:**
   - Update theme colors in `app_theme.dart`
   - Modify categories in `app_constants.dart`
   - Add your affiliate provider logic

2. **Test Thoroughly:**
   - Test on multiple devices
   - Test all user flows
   - Test with different network conditions

3. **Prepare for Production:**
   - Update app icons and splash screens
   - Configure proper app signing
   - Set up CI/CD pipeline
   - Implement proper error tracking (e.g., Sentry, Crashlytics)

4. **Deploy:**
   - Build release APK/IPA
   - Submit to Google Play Store / Apple App Store

---

**Need more help?** Open an issue on GitHub or refer to the main README.md
