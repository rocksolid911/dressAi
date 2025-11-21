# Digital Wardrobe & Smart Outfit Stylist

A comprehensive **AI-powered mobile application** that helps users manage their wardrobe digitally and receive intelligent outfit recommendations based on weather, occasion, and personal style preferences.

## 🌟 Key Features

### Digital Wardrobe Management
- Upload and catalog clothing with automatic AI categorization
- Organize by category, color, season, and occasion
- Track wear frequency and favorite items

### AI-Powered Recommendations
- Daily outfit suggestions based on real-time weather
- Occasion-specific styling (office, party, wedding, date, etc.)
- Mood-based outfit generation (confident, cozy, bold, minimal)
- Natural language processing for custom styling requests

### Smart Features
- Weather integration with OpenWeatherMap
- Outfit planning and calendar scheduling
- Shopping recommendations with affiliate marketing
- Wardrobe analytics and insights

## 🏗️ Architecture

**Frontend:** Flutter (Cross-platform mobile)
**Backend:** Firebase (Auth, Firestore, Storage, Functions)
**AI Services:** OpenAI GPT-4 Vision & GPT-3.5
**Weather:** OpenWeatherMap API
**State Management:** Provider pattern

## 📦 Project Structure

```
wordrobeAI/
├── mobile_app/              # Flutter application
│   ├── lib/
│   │   ├── core/           # Constants, theme, utilities
│   │   ├── models/         # Data models
│   │   ├── services/       # Business logic services
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   └── main.dart       # App entry point
│   ├── pubspec.yaml        # Dependencies
│   └── .env.example        # Environment template
├── functions/              # Firebase Cloud Functions
│   ├── index.js           # Functions implementation
│   └── package.json       # Node dependencies
├── firebase/              # Firebase configuration
│   ├── firestore.rules   # Database security rules
│   └── storage.rules     # Storage security rules
└── docs/                 # Documentation
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- Firebase CLI
- API keys (OpenWeatherMap, OpenAI)

### Installation

```bash
# 1. Clone repository
git clone <repo-url>
cd wordrobeAI

# 2. Set up Firebase
firebase login
firebase init

# 3. Configure Flutter Firebase
cd wardrobe_app
flutterfire configure

# 4. Install dependencies
flutter pub get
cd ../functions && npm install

# 5. Configure environment
cp .env.example .env
# Edit .env with your API keys

# 6. Deploy Firebase
firebase deploy

# 7. Run app
flutter run
```

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions.

## 🔑 Required API Keys

1. **Firebase** - Authentication, Database, Storage, Functions
2. **OpenWeatherMap** - Weather data (free tier available)
3. **OpenAI** - AI image recognition and recommendations (paid)

## 📱 Features Implementation

### AI Services

1. **Image Recognition** - Automatically detects clothing type, color, pattern
2. **Outfit Generator** - Creates combinations based on multiple factors
3. **Natural Language Processing** - Parses user styling requests
4. **Shopping Recommendations** - Suggests items to fill wardrobe gaps

### Core Screens

- Splash & Onboarding
- Authentication (Email/Password, Google)
- Home (Daily recommendations, weather widget)
- Wardrobe (Grid view, filters, search)
- Add Item (Camera, AI analysis)
- Outfit Planner (Combination creator)
- Calendar (Schedule outfits)
- Recommendations (AI suggestions)
- Shopping (Affiliate products)
- Profile (User preferences)

## 🔒 Security

- Firestore security rules enforce user data isolation
- Storage rules limit file sizes and types
- Authentication required for all operations
- API keys secured via environment variables

## 📊 Analytics

Tracks user engagement via Firebase Analytics:
- Sign ups and logins
- Item additions
- Outfit creations
- Recommendation views
- Affiliate clicks

## 🧪 Testing

```bash
# Flutter tests
cd wardrobe_app
flutter test

# Cloud Functions tests
cd functions
npm test
```

## 🚀 Deployment

### Mobile App

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Cloud Functions

```bash
firebase deploy --only functions
```

## 📝 Documentation

- [Detailed Setup Guide](SETUP_GUIDE.md)
- [API Documentation](docs/API.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🛠️ Tech Stack Details

**Mobile:**
- Flutter 3.0+
- Provider (State Management)
- Firebase SDK
- Image Picker
- Cached Network Image

**Backend:**
- Cloud Firestore (NoSQL Database)
- Firebase Authentication
- Firebase Storage
- Cloud Functions (Node.js)

**AI/ML:**
- OpenAI GPT-4 Vision (Image Recognition)
- OpenAI GPT-3.5 Turbo (Recommendations, NLP)
- Custom recommendation algorithms

**APIs:**
- OpenWeatherMap (Weather Data)
- Affiliate networks (Shopping)

## 🎯 Future Enhancements

- [ ] Social features (share outfits)
- [ ] AR virtual try-on
- [ ] Multi-language support
- [ ] Dark mode improvements
- [ ] Offline mode
- [ ] More shopping integrations
- [ ] Style trend analysis

## 📄 License

MIT License - See LICENSE file

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md)

## 💬 Support

- GitHub Issues: Report bugs or request features
- Documentation: Check SETUP_GUIDE.md for common issues

---

**Built with Flutter, Firebase, and AI** ❤️
