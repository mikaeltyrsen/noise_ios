🚀 Noise (iOS App)

Noise is a real-time, live-only social app where your friends appear in a grid.
If someone is offline, their tile shows animated static noise.
When someone goes live, their tile becomes their real-time video stream.

Users can schedule “Noise” broadcasts, design a title overlay, go live instantly, and receive push notifications when their friends are about to make noise.

This repository contains the SwiftUI iOS client for Noise.
The backend is served by the noise_server API (REST + WebSockets).

📱 Tech Stack

SwiftUI

MVVM (feature-based architecture)

Agora (live video streaming)

WebSockets (presence + real-time updates)

REST API (users, auth, streams)

Push Notifications (APNS)

Local caching (UserDefaults + FileManager)

🧱 Architecture Overview

Noise uses a feature-based MVVM structure with a set of shared services & managers.

Architecture Goals

Keep Views simple and declarative

Keep logic inside ViewModels + Managers

Group features into modular, isolated folders

Move reusable UI into /Shared

Provide consistent structure so Codex can generate new code accurately

📁 Project Folder Structure
Noise/
│
├── App/
│   ├── NoiseApp.swift
│   ├── AppCoordinator.swift
│   ├── Launch/
│   │   ├── LaunchView.swift
│   │   └── LaunchViewModel.swift
│   └── Root/
│       ├── RootView.swift
│       └── RootViewModel.swift
│
├── Features/
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── LiveGridView.swift
│   │   │   └── NoiseTileView.swift
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift
│   │   └── Models/
│   │       └── NoiseStream.swift
│
│   ├── LiveStream/
│   │   ├── Views/
│   │   │   ├── LiveStreamView.swift
│   │   │   ├── TitleOverlayView.swift
│   │   │   └── CountdownView.swift
│   │   ├── ViewModels/
│   │   │   └── LiveStreamViewModel.swift
│   │   └── Models/
│   │       └── StreamSettings.swift
│
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── ProfileViewModel.swift
│
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│
│   └── Schedule/
│       ├── ScheduleView.swift
│       ├── ScheduleViewModel.swift
│       └── ScheduledNoise.swift
│
├── Managers/
│   ├── AuthManager.swift
│   ├── APIManager.swift
│   ├── AgoraManager.swift
│   ├── VideoManager.swift
│   ├── PushNotificationManager.swift
│   └── UserManager.swift
│
├── Services/
│   ├── API/
│   │   ├── APIClient.swift
│   │   └── Endpoints.swift
│   ├── Storage/
│   │   ├── LocalStorage.swift
│   │   └── CacheService.swift
│   ├── Realtime/
│   │   ├── WebSocketService.swift
│   │   └── PresenceService.swift
│   └── Analytics/
│       └── AnalyticsService.swift
│
├── Shared/
│   ├── Components/
│   │   ├── AvatarView.swift
│   │   ├── NoiseStaticView.swift
│   │   ├── PrimaryButton.swift
│   │   ├── FloatingActionButton.swift
│   │   └── CountdownCircleView.swift
│   ├── Extensions/
│   │   ├── Color+Ext.swift
│   │   ├── View+Ext.swift
│   │   ├── Date+Ext.swift
│   │   └── String+Ext.swift
│   ├── Modifiers/
│   │   ├── NoiseTitleModifier.swift
│   │   └── FadeInModifier.swift
│   └── Styles/
│       ├── Fonts.swift
│       └── Theme.swift
│
└── Resources/
	├── Assets.xcassets
	├── AppIcon.appiconset
	└── Preview Content/

🔌 Server API Overview

The iOS app communicates with the Noise backend using:

JSON REST endpoints

Token-based authentication

WebSockets for real-time presence & stream events

Base URL
https://noise.yourdomain.io/api/

Required Headers
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json

🔐 Authentication
POST /register
{
  "email": "test@example.com",
  "password": "1234"
}

POST /login

Response includes:

{
  "success": true,
  "token": "...",
  "user": { ... }
}


Token must be stored in LocalStorage and added to all requests.

📡 Streams API
GET /streams/active

Returns current live users:

[
  {
	"user_id": "123",
	"name": "Mikael",
	"live": true,
	"title": "In the studio",
	"started_at": 1729300000
  }
]

POST /streams/start
{
  "title": "My Noise"
}

POST /streams/stop
🔄 WebSocket

A persistent WebSocket connection is used to:

update the home grid in real time

broadcast presence status

detect when a friend goes live

detect when a stream stops

The WebSocket client lives in:

Services/Realtime/WebSocketService.swift

🎨 Coding Conventions
Files

Views → FeatureName/ViewName.swift

ViewModels → ViewModel suffix

Models → singular nouns (User.swift, NoiseStream.swift)

Managers → SomethingManager.swift

SwiftUI Rules

No business logic in Views

Use @StateObject for main view models

Use @ObservedObject for child view models

Use @Published for state that drives UI

Network Rules

All API calls go through APIManager

Endpoints defined in Endpoints.swift

Use async/await

Use Codable models

🤖 How Codex Should Generate Code

Codex should ALWAYS follow:

File placement

Views → Features/<Feature>/Views/

ViewModels → Features/<Feature>/ViewModels/

Models → Features/<Feature>/Models/

New services → Services/

Global logic → Managers/

Reusable UI → Shared/Components/

Example Codex prompt

Add a FriendsList feature.
Create:

FriendsListView (SwiftUI)

FriendsListViewModel

Friend model
Place files in Features/FriendsList/...
Fetch friend data from /friends/list using APIManager.

🧪 Running the App
open Noise.xcodeproj


Requirements:

iOS 17+

Swift 5.10

Xcode 16+

🤝 Contribution Guidelines

Follow the folder structure exactly

Do not put logic in views

Keep network code inside managers/services

Use dependency injection when possible

Use async/await for all async operations

🎯 Codex Goal

Codex should understand:

Project architecture

Folder layout

Design patterns

Naming rules

Where new code should go

How the server API works

How real-time updates integrate into the UI

This README acts as the “blueprint” for future auto-generated features.