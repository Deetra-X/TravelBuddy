# Quick Reference: Supabase Auth Implementation

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI App                             │
│                                                               │
│  RootView (checks session on launch)                          │
│      │                                                        │
│      ├─► Initializing?                                        │
│      │   └─► Load SessionManager from Keychain               │
│      │                                                        │
│      ├─► isAuthenticated?                                     │
│      │   ├─► YES ──► Home Screen                             │
│      │   └─► NO ──► Auth Flow                                │
│      │                                                        │
│      └─► AuthFlowView                                         │
│          ├─► SignInScreen                                    │
│          │   └─► AuthViewModel.login()                       │
│          │       └─► AuthService + SessionManager            │
│          │           └─► Save token in Keychain             │
│          │                                                   │
│          └─► SignUpScreen                                    │
│              └─► AuthViewModel.register()                    │
│                  └─► AuthService + SessionManager            │
│                      └─► Save token in Keychain             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
TravelBuddy/
├── Auth/
│   ├── Services/
│   │   ├── AuthService.swift        (👈 API calls + session save)
│   │   └── SessionManager.swift     (👈 NEW - Keychain + token mgmt)
│   ├── ViewModels/
│   │   └── AuthViewModel.swift      (👈 Updated - logout + session)
│   ├── Screens/
│   │   ├── SignInScreen.swift
│   │   ├── SignUpScreen.swift
│   │   └── ...
│   ├── Network/
│   │   └── AuthEndpoints.swift
│   └── Models/
│       └── AuthModels.swift
├── Navigation/
│   └── RootView.swift               (👈 Updated - session check)
└── SUPABASE_SETUP.md               (👈 This guide)
```

## Data Flow: Login

```
1. User enters email + password
   └─► SignInScreen

2. SignUpScreen calls:
   await viewModel.login(email, password)
   └─► AuthViewModel

3. AuthViewModel calls:
   try await service.login(email, password)
   └─► AuthService

4. AuthService:
   • Validates input
   • Sends to Supabase: POST /auth/v1/token
   • Receives: user data + access_token + refresh_token
   └─► Returns AuthUser

5. AuthService also calls:
   try await sessionManager.saveSession(authSession)
   └─► SessionManager

6. SessionManager:
   • Encodes AuthSession (includes tokens)
   • Saves to Keychain (encrypted)
   • Saves user info to UserDefaults
   └─► Done

7. AuthViewModel updates @Published var currentUser
   └─► UI triggers navigation to Home

8. Next app launch:
   • RootView creates SessionManager()
   • SessionManager.__init__ calls loadSession()
   • Keychain returns saved AuthSession
   • RootView navigates to Home directly
```

## Data Flow: Database Access (Future)

```
When querying user data:

1. Any ViewModel/Service needs data
   └─► Must include: Authorization: Bearer {accessToken}
   
2. Supabase validates token
   └─► Decodes JWT to get user_id
   
3. RLS policies check
   └─► Only return rows where user_id = authenticated user
   
4. User can only see their own data
   └─► RLS prevents data leaks
```

## Key Components Explained

### SessionManager
- **Responsibility**: Manages user session lifecycle
- **Storage**: Keychain (encrypted by iOS)
- **Properties**:
  - `currentSession: AuthSession?`
  - `isAuthenticated: Bool`
- **Methods**:
  - `saveSession(_:)` - Save after login
  - `loadSession()` - Restore on app launch
  - `clearSession()` - Clear on logout
  - `refreshToken(_:)` - Refresh expired token

### AuthSession
```swift
struct AuthSession {
    let accessToken: String         // JWT token for API calls
    let refreshToken: String?       // Token to get new access token
    let userId: String             // Supabase user ID
    let userEmail: String          // User email
    let userName: String           // User display name
    let expiresAt: Date?           // When token expires
}
```

### AuthService Changes
```swift
// BEFORE: Just made API calls
login() throws -> AuthUser

// AFTER: Makes API calls + saves session
login() throws -> AuthUser {
    // ... API call ...
    try await sessionManager.saveSession(authSession)
    return authUser
}
```

## Security Implementation

```
┌─────────────────────────────────────────────────┐
│        iOS Keychain (Hardware Encrypted)         │
│                                                  │
│  access_token ────────┐                         │
│  refresh_token ───────┼─► Only app can read     │
│  user_id ─────────────┤   Even if phone stolen  │
│  expires_at ──────────┘                         │
└─────────────────────────────────────────────────┘

UserDefaults (Not encrypted - quick cache)
│
├─ user_id    (public, used to identify user)
├─ user_email (public, displayed in UI)
└─ user_name  (public, displayed in UI)
```

## Common Tasks

### Check if User is Logged In
```swift
@EnvironmentObject var sessionManager: SessionManager

if sessionManager.isAuthenticated {
    // Show home screen
} else {
    // Show login screen
}
```

### Get Current User Info
```swift
if let session = sessionManager.currentSession {
    print(session.userName)
    print(session.userEmail)
    print(session.userId)
}
```

### Logout User
```swift
@ObservedObject var viewModel: AuthViewModel

func logout() {
    Task {
        await viewModel.logout()
        // Navigation handled automatically
    }
}
```

### Make Authenticated API Call (Future)
```swift
// Assuming you extend AuthService for profile queries

let request = URLRequest(url: dataURL)
request.setValue("Bearer \(session.accessToken)", 
                forHTTPHeaderField: "Authorization")
// This tells Supabase: "User is \(userId)" via JWT decode
// RLS policies then filter results
```

## Testing Checklist

- [ ] **Sign Up**: Create new account → Verify session saved
- [ ] **Sign In**: Login with existing account → Verify session saved
- [ ] **Session Persistence**: Kill app → Reopen → Should go to Home (not Auth)
- [ ] **Invalid Credentials**: Try login with wrong password → Error shown
- [ ] **Token Format**: Check Keychain has valid JWT (use Terminal)
- [ ] **Logout**: Logout → Kill app → Reopen → Should go to Auth
- [ ] **Profile Creation**: Signup → Check Supabase that profile row created
- [ ] **RLS Policies**: Verify users can only query own profile

## Supabase Dashboard Actions

1. **Check Profiles Table**
   - Go to: https://app.supabase.com → Your Project → SQL Editor
   - Run: `SELECT * FROM profiles;`
   - Should see rows for each registered user

2. **Check RLS Policies**
   - Go to: Auth → Policies
   - Should see 3 policies on `profiles` table (select, insert, update)

3. **Check Email Settings**
   - Go to: Auth → Email Templates
   - Verify custom domain if needed

4. **Monitor Logs**
   - Go to: Database → Logs
   - Watch for queries as users login/signup

## Future Enhancements

1. **Token Refresh** - Implement automatic refresh when expired
2. **Multi-Device** - Allow login on multiple devices
3. **Social Auth** - Add Google/Apple OAuth
4. **2FA** - Add two-factor authentication
5. **Remember Me** - Shorter logout timeout, or stay logged in
6. **Email Verification** - Required before using app
7. **Phone Auth** - SMS-based authentication option

