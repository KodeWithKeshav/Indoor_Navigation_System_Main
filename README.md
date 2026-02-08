# Indoor Navigation System

> **Project Status:** ✅ Active Development
> **Modules Completed:** Admin Map Management, Pathfinding Engine, Basic User Navigation via Trip Planner.
> **Connectivity:** Firebase via `cloud_firestore` (Admin Module).

---

## 📖 Project Overview

The **Indoor Navigation System** is a mobile application designed to solve the problem of wayfinding in complex indoor environments (universities, hospitals, malls). Unlike GPS, which fails indoors, this system uses a custom graph-based pathfinding engine to guide users through buildings, floors, and rooms.

### 🎨 Design Philosophy
Inspired by *Don Norman’s "The Design of Everyday Things"*, the UI focuses on:
*   **Affordance:** Clear buttons and interactive map elements.
*   **Feedback:** Instant visual feedback during path calculation and error states.
*   **Accessibility:** "Deep Void" dark theme with high contrast for better visibility.

---

## 🚀 Project Status

| Module | Status | Connectivity | Description |
| :--- | :--- | :--- | :--- |
| **Admin Map Management** | ✅ 100% | **Firebase** | CRUD operations for Buildings, Floors, Rooms, and Corridors. |
| **Pathfinding Engine** | ✅ 100% | Local Graph | A* Algorithm implementation with multi-floor support. |
| **User Trip Planner** | ✅ 90% | Local/State | UI for selecting Start/End points, Swapping, and Search. |
| **Navigation UI** | 🟡 70% | Local/State | Step-by-step instructions (Voice pending). |
| **Authentication** | ✅ 100% | **Firebase Auth** | Role-based login (Admin/Student/Guest). |

**Current Phase:** Core Infrastructure & Basic Navigation.

---

## 🛠 Tech Stack

| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Dart) | Cross-platform mobile UI. |
| **State Management** | Riverpod | efficient state caching and dependency injection. |
| **Backend** | Firebase Firestore | Storing map data (Nodes, Edges, Metadata). |
| **Auth** | Firebase Auth | Secure user authentication. |
| **Pathfinding** | Custom A* | Calculating shortest paths locally on device. |

---

## 🧪 Testing Strategy

For Sprint 1, we have identified and implemented **Unit Testing** using the standard Flutter test framework.

### Tool Used: `flutter_test`

*   **Why?** Integrated directly into Flutter, fast execution, and supports widget testing.
*   **Scope:** Testing the `PathfindingService` logic and `TripPlannerWidget` UI rendering.

### How to Run Tests
Open your terminal in the project root and run:

```bash
flutter test
```

**Sample Test Output:**
```text
00:02 +1: ... pathfinding_service_test.dart
00:03 +1: ... trip_planner_widget_test.dart
00:04 +2: All tests passed!
```

---



---

## 📂 Project Structure

```
lib/
├── core/                   # Shared logic (A* Algorithm, Theme)
├── features/
│   ├── admin_map/          # Module: Map Management (Connectivity Implemented)
│   │   ├── data/           # Firestore Repositories
│   │   ├── domain/         # Entities & Use Cases
│   │   └── presentation/   # Admin UI Screens
│   ├── navigation/         # Module: User Wayfinding
│   ├── auth/               # Module: Authentication
└── main.dart               # Entry Point
```

---

## 🔧 Setup & Installation

1.  **Clone the Repo:**
    ```bash
    git clone https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main.git
    cd Indoor_Navigation_System_Main
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the App:**
    ```bash
    flutter run
    ```
    *Note: Valid `google-services.json` required for Firebase connectivity.*

---

## 📝 Code Quality & Comments

*   All critical logic (especially `pathfinding_service.dart`) is documented with comments explaining the algorithm steps.
*   Widget trees are broken down into small, reusable components.

---

### 👨‍💻 Developed by (Team)

| Name | Roll Number |
| :--- | :--- |
| **Keshav S** | CB.SC.U4CSE23222 |
| **Abinaya S** | CB.SC.U4CSE23237 |
| **Suhitha S** | CB.SC.U4CSE23244 |
| **Jayaram S** | CB.SC.U4CSE23255 |
| **Prithiv** | CB.SC.U4CSE23260 |

