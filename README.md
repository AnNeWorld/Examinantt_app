# 🎓 Examinantt – EdTech & Competitive Exam Preparation App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Razorpay](https://img.shields.io/badge/Payment-Razorpay-02042B?logo=razorpay&logoColor=white)](https://razorpay.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

**Examinantt** ek modern, high-performance aur fully responsive competitive examination preparation mobile app hai (JEE Main/Advanced, NEET UG, CUET, SSC CGL, GATE, Boards). Isme real-time Firebase architecture, comprehensive Batch Management, Test Series engine, Study Material (PDFs/Notes), Live Classrooms aur interactive Community Chat shamil hain.

---

## 🌟 Key Highlights & Modules

### 1. 🏫 Batch Management & Dynamic Relations
- **Batch Creation & Editing**: Admin/Teacher mode me custom batches create karein with target exams, start/end dates, pricing aur features.
- **Dynamic Content Association**: Test Series aur Resources ko dynamically kisi bhi batch ke sath link ya unlink karein (`batchId` aur `batchIds` architecture).
- **Dedicated Batch Details Screen**:
  - **Resources Tab**: Us batch se linked sabhi study materials aur PDFs.
  - **Live Classes Tab**: Scheduled aur completed live lecture streams.
  - **Test Series Tab**: Batch-specific mock tests aur evaluation papers.

### 2. 📚 Resources & Study Material Hub
- **Multi-Batch Assignment**: Ek hi resource multiple batches me assign karne ki suvidha (`batchIds: [...]`).
- **Tab Filters**: Filter by Subjects, Categories, aur Batches.
- **Integrated PDF Reader**: In-app caching aur high-speed rendering via `flutter_cached_pdfview`.
- **Admin Resource Management**: Dynamic Add/Edit/Delete sheets with upload progress.

### 3. 🎯 Advanced Test Series & Quiz Engine
- **Hierarchical Test Types**: Full-length tests, subject tests, chapter-wise tests aur unit tests.
- **Real-time Exam Simulation**:
  - Live countdown timer
  - Interactive Question Palette (Visited, Answered, Marked for Review)
  - Subject switching (Physics, Chemistry, Maths, etc.)
  - Bookmark questions for later review
- **Detailed Instant Analytics**: Accuracy, percentile, score breakdown, solution review with explanations.

### 4. 🔴 Live Classes & Video Lectures
- Live streams and pre-recorded classes support (`youtube_player_iframe` & `video_player`).
- Notification reminder toggles (Alert Set for upcoming lectures).
- Subject-wise and teacher-wise categorization.

### 5. 💬 Student Community & Doubts Resolution
- **Community Chat Rooms**: Real-time group messaging with instant sync via Firestore streams.
- **Doubt Solver**: Subject-wise doubts submit karein aur peer/mentor explanations paayein.

### 6. 💳 Seamless Monetization & Purchases
- **Razorpay Checkout Integration**: Multi-platform payment pipeline (Android, iOS, Web stub).
- **My Purchases & Enrolled Batches**: Instant unlock across Locked vs. Unlocked Home experience.
- Automated payment verification aur Firestore ledger update.

### 7. 🌗 Modern UI/UX & Dark/Light Theme
- Rich dark/light theme support powered by `ThemeProvider` aur HSL-curated color tokens (`AppColors`).
- Micro-animations using `flutter_animate` aur modern typography with Google Fonts (`Poppins`).
- Responsive layout across phones, tablets aur foldables.

---

## 🏗️ Architecture & Technology Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.10) | Cross-platform client framework |
| **State Management** | Provider | Reactive state management (`UserProvider`, `ThemeProvider`) |
| **Backend & Database** | Firebase Cloud Firestore | Real-time streams, reactive query indices |
| **Authentication** | Firebase Auth | Phone/Email authentication with Pinput OTP |
| **Payments** | Razorpay Flutter | Gateway SDK with multi-platform stubbing |
| **Video & Media** | Video Player / YouTube IFrame | Dual-engine video rendering |
| **PDF Handling** | Flutter Cached PDFView | Native high-performance PDF renderer |
| **Analytics & Charts** | FL Chart | Performance curves, score distributions |

---

## 📂 Project Directory Structure

```plaintext
examinantt_app/
├── android/                   # Native Android configuration & manifests
├── assets/                    # App icons, splash animations & graphics
├── ios/                       # Native iOS configuration & Podfile
├── web/                       # Web build configurations & PWA manifests
├── lib/
│   ├── auth_screen/           # Auth flow (Splash, Welcome, Login, Signup, OTP)
│   ├── constants/             # Colors (AppColors), image assets, API constants
│   ├── models/                # Typed data models:
│   │   ├── content_models.dart       # Resources, Batches, Live Classes, Alerts
│   │   ├── test_model.dart           # Tests, Questions, Results, Bookmarks
│   │   ├── user_model.dart           # User profile & credentials
│   │   └── community_message_model.dart # Chat messages & payloads
│   ├── providers/             # Global Providers:
│   │   ├── user_provider.dart        # User session & purchase state
│   │   └── theme_provider.dart       # Dark/Light theme switching
│   ├── screens/               # Core screens:
│   │   ├── home_screen.dart          # Dynamic Locked / Unlocked Home
│   │   ├── main_screen.dart          # Bottom navigation bar root
│   │   ├── courses_screen.dart       # Batches & Course listings
│   │   ├── batch_details_screen.dart # Batch Hub (Resources, Live, Tests)
│   │   ├── test_series_screen.dart   # Test series listings & filters
│   │   ├── quiz_screen.dart          # Real-time CBT examination screen
│   │   ├── resources_screen.dart     # PDFs, study material & notes
│   │   ├── live_classes_screen.dart  # Live lectures & schedules
│   │   ├── checkout_screen.dart      # Cart & Payment processing
│   │   ├── profile_screen.dart       # Account, streaks & target exams
│   │   └── ...                       # Analytics, Doubts, PYQs, Notifications
│   ├── services/              # Business logic & APIs:
│   │   ├── firestore_service.dart    # Central Firestore operations & streams
│   │   ├── content_service.dart      # Resources & batches query service
│   │   ├── test_service.dart         # Questions, quiz submissions & history
│   │   └── payment_service.dart      # Razorpay payment handler
│   ├── utils/                 # AppTheme, validators, formatters
│   └── widgets/               # Reusable UI components & bottom sheets:
│       ├── create_edit_batch_sheet.dart    # Batch builder with dynamic links
│       ├── create_edit_resource_sheet.dart # Resource uploader & batch linker
│       ├── locked_home_sections.dart       # Un-enrolled user showcase
│       ├── unlocked_home_sections.dart     # Enrolled student dashboard
│       └── quick_access_widget.dart        # 6-card quick launch pad
└── pubspec.yaml               # App configuration & package dependencies
```

---

## 🚀 Getting Started & Setup Guide

### 1. Prerequisites
- **Flutter SDK**: `^3.10.4` or later installed ([Flutter Install Guide](https://docs.flutter.dev/get-started/install)).
- **Dart SDK**: Bundled with Flutter.
- **Android Studio** / **VS Code** with Flutter & Dart extensions.
- **Firebase Account** with a configured Firestore & Auth project.

### 2. Clone & Install Dependencies
```bash
# Clone the repository
git clone https://github.com/your-username/examinantt-app.git

# Navigate to the project directory
cd "examinantt app"

# Get all required packages
flutter pub get
```

### 3. Firebase Configuration
1. Project me Android ke liye `android/app/google-services.json` setup karein.
2. Web ya iOS platforms ke liye Firebase CLI se `flutterfire configure` run karein.
3. Firestore Database rules me read/write security permissions verify karein.

### 4. Running the Application
```bash
# Available devices check karein
flutter devices

# Development mode me app run karein
flutter run

# Release mode me test karein
flutter run --release
```

---

## 🧪 Testing & Code Quality

Code quality aur static analysis rules verify karne ke liye:

```bash
# Static analysis check karein (Must be 0 errors & 0 warnings)
flutter analyze

# Unit & widget tests run karein
flutter test
```

---

## 📦 Building for Production

### Android APK / App Bundle:
```bash
# Split APKs for small download size
flutter build apk --split-per-abi

# Production AAB for Google Play Store
flutter build appbundle --release
```

### Web Release:
```bash
flutter build web --release
```

---

## 🔐 Security & Best Practices
- **Never commit secret keys**: `play-store-key.json`, upload keystores, aur private API secrets `.gitignore` me included hain.
- **Firestore Security Rules**: Sabhi collections (`users`, `purchases`, `batches`, `tests`) authenticated queries par structured hain.
- **Safe Context Usage**: Async operations ke baad hamesha `mounted` guard lagaya gaya hai memory leaks aur crashes prevent karne ke liye.

---

## 👥 Contributors & Support
Developed with ❤️ for **Examinantt Education**.
- Website: [examinantt.com](https://www.examinantt.com)
- Support: `support@examinantt.com`
