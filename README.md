<p align="center">
  <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSkola0yN__TwEocKJTw9MV2wq3Rj75PWsCmw&s" alt="Namekart Logo" width="150"/>
</p>

<h1 align="center">Namekart Mobile</h1>

<p align="center">
  <strong>The official mobile command center for the Namekart domain intelligence platform.</strong>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/platform-Flutter-005CF7?style=for-the-badge&logo=flutter" alt="Platform">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/status-in%20development-F7B500?style=for-the-badge" alt="Status">
  </a>
    <a href="#">
    <img src="https://img.shields.io/badge/state%20management-Provider-546E7A?style=for-the-badge&logo=flutter" alt="State Management">
  </a>
</p>

<p align="center">
  <!-- Replace with a high-quality GIF of your app in action -->
  <img src="https://user-images.githubusercontent.com/8325299/214695999-a9a7c632-349c-4ce3-a20c-b26a1112e431.gif" alt="Namekart App Demo"/>
</p>

---

## 🚀 Introduction

Welcome to the **Namekart Mobile** repository. This Flutter-based application is the official, high-performance mobile companion to the main Namekart platform. It is engineered from the ground up to provide domain investors with a real-time command center to track auctions, manage data, and seize opportunities on the go. The application is built with a focus on three core tenets: **performance**, **real-time data synchronization**, and a **clean, intuitive user experience**.

This document provides a comprehensive technical guide for developers, covering everything from the core features and in-depth architecture to the project structure, data flow, and setup process.

## ✨ Core Features: A Technical Overview

The application is packed with features designed for power users, focusing on workflow enhancement and providing critical, time-sensitive information.

| Feature                      | Technical Implementation Details                                                                                                                                                                                                                          |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ⚡️ **Real-Time Notifications** | A persistent **WebSocket** connection (`WebSocketService`) streams live data, which is then parsed and dispatched to the appropriate `ChangeNotifier`. **Firebase Cloud Messaging (FCM)** (`FcmHelper`) handles background/terminated state push notifications to ensure immediate user alerting. |
| 🔐 **Microsoft Authentication** | Secure sign-on is handled by the `msal_auth` package. The `MicrosoftLoginButton` widget initiates the OAuth flow. Upon successful authentication, user tokens and profile data are securely stored in the local SQLite database (`DbAccountHelper`) for session persistence and auto-login. |
| 🎯 **Personal Groups** | This powerful feature allows users to define complex, server-side filtering rules. The mobile client provides the UI (`PersonalGroup.dart`, `PersonalGroupDetails.dart`) for creating and managing these rules, which are then synced to Firestore for the backend to apply against the live data stream. |
| 🚀 **Advanced Auction Tools** | **Bulk Fetch**: Asynchronously fetches data for up to 5 domains from multiple registrars (GoDaddy, Dynadot, Namecheap) via HTTP POST requests managed by `api_service.dart`. Results are displayed in `BulkFetchListScreen.dart`. **Bulk Bid**: A streamlined interface in `BulkBid.dart` to place multiple bids through a single API call. |
| 📂 **Data Management** | **Watchlist & Bidding List**: Separate screens (`WatchlistScreen.dart`, `BiddingListAndWatchListScreen.dart`) that query the local SQLite database for items flagged by the user, providing fast, offline-first access to curated lists. |
| ✍️ **Productivity Suite** | **Quick Notes**: A simple CRUD interface (`QuickNotesScreen.dart`) for storing text notes locally. **Contextual Metadata**: Users can add Stars, Hashtags, and Notes directly to auction items. This metadata is persisted locally and associated with the specific notification ID. |
| 🔍 **Universal Search** | The `SearchScreen.dart` performs a comprehensive client-side search across multiple tables in the local SQLite database, indexing notifications, channels, and personal notes for instant, aggregated results. |
| 📊 **Data Analytics** | The `AnalyticsScreen.dart` queries the local database for notification data, aggregates it by day, and uses a custom bar chart widget to visualize the user's daily notification volume and activity trends. |

## 🏗️ In-Depth Architecture

The application employs a robust, multi-layered architecture designed for reactivity, scalability, and offline-first functionality.

#### 1. State Management (`Provider` + `ChangeNotifier`)
The core of the app's reactivity lies in the `provider` package.
- **`AllDatabaseChangeNotifiers.dart`**: This central file defines a suite of `ChangeNotifier` classes, each responsible for a specific slice of the application's state (e.g., `LiveDatabaseChange`, `NotificationDatabaseChange`, `UserSettingsChangeNotifier`).
- **Data Flow**: When new data arrives (e.g., from WebSockets or Firestore sync), the relevant service updates the corresponding `ChangeNotifier`. Widgets that listen to these notifiers (using `Consumer` or `context.watch`) are then automatically and efficiently rebuilt. This decoupled approach keeps UI logic separate from business logic.

#### 2. Data Persistence & Synchronization (The "Offline-First" Strategy)
The app is engineered to be fully functional even with intermittent connectivity.
- **Primary Local Storage (SQLite)**: Managed by `DbSqlHelper.dart`, this is the app's workhorse. It stores all user data, notifications, settings, and metadata. The schema is optimized for fast queries, which power the entire UI.
- **Cloud Source of Truth (Firestore)**: Managed by `FirestoreHelper.dart`, Firestore is used for data backup and multi-device sync.
- **Synchronization Logic**:
  1.  **Initial Sync**: On first login (`ResourcesIntializationScreen.dart`), the app performs a bulk download of necessary data from Firestore to hydrate the local SQLite database.
  2.  **Delta Sync**: On subsequent logins, the app intelligently queries Firestore for documents created or modified since the last sync timestamp, ensuring minimal data transfer.
  3.  **Data Retention**: To manage device storage and maintain high performance, a cleanup job runs periodically to purge local data older than two days.

#### 3. Backend Communication Layer
- **`WebSocketService.dart`**: This is more than just a connection handler. It's a stateful service that:
    - Maintains a persistent connection to the backend.
    - Implements an exponential backoff strategy for automatic reconnection.
    - Listens for incoming messages, parses the JSON payload, and calls the appropriate functions in `GlobalFunctions.dart` or updates a `ChangeNotifier` to propagate the new data throughout the app.
- **`api_service.dart`**: This service encapsulates all RESTful API communication. It handles HTTP POST requests for actions that are transactional and don't require a persistent connection, such as submitting bids or fetching bulk data.

## 🎨 UI/UX Philosophy & Key Components

The user experience is defined by its fluidity, responsiveness, and attention to detail.
- **`AuctionListItem.dart`**: This is the most complex widget in the app. It's a `StatefulWidget` that manages its own state (read/unread, expanded/collapsed) and uses a `VisibilityDetector` to trigger read-on-view functionality.
- **Custom Animations**:
    - **`SuperAnimatedWidget.dart`**: A powerful wrapper that combines fade, scale, and slide transitions to create sophisticated entrance animations for lists and cards.
    - **`AnimatedSlideTransition.dart` & `AnimatedAvatarIcon.dart`**: Bespoke animation widgets providing granular control over UI element transitions.
- **`customSyncWidget.dart` (`AlertWidget`)**: A high-order component that wraps primary screens. It listens to connectivity and WebSocket status notifiers to display non-intrusive alerts (e.g., "Connecting...", "Offline"), enhancing user awareness of the app's state.
- **`CustomShimmer.dart`**: Provides elegant, content-aware shimmer loading effects that mimic the layout of the content being loaded, creating a seamless and professional user experience.

## 🚀 Getting Started

Follow these steps to get the project running on your local machine for development and testing.

#### **Prerequisites:**

* Flutter SDK (latest stable version)
* An editor like VS Code or Android Studio
* A configured emulator or physical device

#### **Setup Instructions:**

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd namekart_mobile
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration (Critical):**
    * Follow the official FlutterFire documentation to create and configure a Firebase project.
    * Place your generated `google-services.json` (for Android) in the `android/app/` directory.
    * Place your `GoogleService-Info.plist` (for iOS) in the `ios/Runner/` directory.
    * In the Firebase console, ensure you have enabled **Firestore Database** and **Firebase Authentication**.

4.  **Run the Application:**
    ```bash
    flutter run
    ```

---

<p align="center">
  <em>This project is a testament to robust mobile architecture. Happy coding!</em>
</p>
