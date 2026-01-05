# Monios Setup Guide

## Project Structure

```
Monios/
├── Monios/                    # iOS App
│   ├── MoniosApp.swift        # App entry point
│   ├── ContentView.swift      # Root view with auth routing
│   ├── LoginView.swift        # Login screen
│   ├── ChatView.swift         # Chat interface
│   ├── SessionView.swift      # Session sidebar
│   ├── Message.swift          # Message model and views
│   ├── Theme.swift            # Terminal aesthetic styling
│   ├── AuthManager.swift      # Auth state management
│   └── APIClient.swift        # HTTP client for backend
│
└── backend/                   # FastAPI Backend
    ├── main.py                # Server entry point
    ├── config.py              # Environment configuration
    ├── auth/                  # Authentication module
    │   ├── google.py          # Google token verification
    │   ├── jwt.py             # JWT creation/validation
    │   └── middleware.py      # Auth middleware
    └── routes/                # API routes
        ├── auth.py            # /auth/* endpoints
        └── chat.py            # /api/* endpoints
```

## Backend Setup

### 1. Create virtual environment
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your settings
```

### 3. Get Google OAuth credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project (or select existing)
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials (iOS app type)
5. Copy the Client ID to `.env`

### 4. Run the server
```bash
python main.py
# or
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## iOS Setup

### 1. Add Google Sign-In SDK (optional for full Google auth)
In Xcode: File → Add Package Dependencies
URL: `https://github.com/google/GoogleSignIn-iOS`

### 2. Configure Info.plist for Google Sign-In
Add URL scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID`

### 3. Update API base URL
Edit `APIClient.swift` and set your server URL:
```swift
#if DEBUG
static let baseURL = "http://localhost:8000"
#else
static let baseURL = "https://your-server.com"
#endif
```

### 4. Run the app
Open `Monios.xcodeproj` in Xcode and run on simulator or device.

## API Endpoints

### Public
- `POST /auth/google` - Authenticate with Google ID token
- `POST /auth/refresh` - Refresh access token

### Protected (requires Bearer token)
- `POST /api/chat` - Send chat message
- `GET /api/chat/history` - Get chat history
- `GET /api/session` - Get session info

## Authentication Flow

```
1. User signs in with Google/Apple on iOS
2. iOS sends ID token to POST /auth/google
3. Backend verifies token with Google
4. Backend returns JWT access + refresh tokens
5. iOS stores tokens in Keychain (currently UserDefaults for dev)
6. All /api/* requests include: Authorization: Bearer <access_token>
7. When access token expires, use refresh token to get new tokens
```

## Security Notes

- Access tokens expire in 30 minutes
- Refresh tokens expire in 7 days
- In production, store tokens in Keychain, not UserDefaults
- The chat API returns 401 if no valid token is provided
- JWT secret should be a strong random string in production

## TestFlight Distribution

1. Join Apple Developer Program ($99/year)
2. Create app in App Store Connect
3. In Xcode: Product → Archive
4. Distribute App → App Store Connect
5. Add testers in TestFlight section
6. Testers receive invite via email

## Development Mode

The app includes a "dev mode" button on the login screen that bypasses real authentication for testing. Toggle between local/online mode in the chat header to test with or without the backend.
