# TravelBuddy Supabase Authentication Setup Guide

## ✅ What's Been Set Up

Your TravelBuddy app now has a complete authentication system integrated with Supabase. Here's what was implemented:

### 1. **Supabase Connection Details**
   - **Host**: `db.vnqqgxyakcbkeoualauc.supabase.co`
   - **Database**: `postgres`
   - **Port**: `5432`
   - **User**: `postgres`
   
   Already configured in `AuthEndpoints.swift` with your Anon Key.

### 2. **Database Schema**
   - **profiles** table: Stores user profile data (id, full_name, created_at, updated_at)
   - **Row Level Security (RLS)**: Enabled to ensure users can only access their own data
   - **Auto-trigger**: When a user signs up, a profile is automatically created

### 3. **Session Management System**
   
   #### New Files Created:
   - **SessionManager.swift**: Handles secure token storage and session lifecycle
     - Stores tokens in iOS Keychain (encrypted)
     - Caches user info in UserDefaults for quick access
     - Manages token expiration and refresh
   
   #### Key Features:
   - ✅ Secure token storage using Keychain
   - ✅ Automatic session loading on app launch
   - ✅ Token refresh capability
   - ✅ Session expiration tracking

### 4. **Authentication Flow**

   ```
   User Signs Up/In
        ↓
   AuthViewModel receives credentials
        ↓
   AuthService validates and sends to Supabase
        ↓
   Supabase returns access token + user data
        ↓
   SessionManager stores token in Keychain
        ↓
   User profile saved to UserDefaults
        ↓
   App navigates to Home
   ```

### 5. **App-Level Session Check**
   
   The `RootView.swift` now:
   - Checks for existing session on app launch
   - Shows loading screen while checking
   - Routes directly to Home if session valid
   - Routes to Onboarding if no valid session
   - Provides logout functionality

## 🔑 Key Classes & Their Responsibilities

### SessionManager
```swift
// Load existing session from Keychain
let session = await sessionManager.loadSession()

// Save new session after login
try await sessionManager.saveSession(authSession)

// Clear session on logout
try await sessionManager.clearSession()

// Check if user is authenticated
if sessionManager.isAuthenticated { ... }
```

### AuthService (Updated)
Now accepts `SessionManager` and automatically:
- Saves session after successful login/signup
- Stores user tokens securely
- Tracks token expiration

### AuthViewModel (Updated)
- Added `logout()` method that clears session
- Integrated with SessionManager
- Proper session lifecycle management

## 📱 User Flow Examples

### Scenario 1: User Launches App (First Time)
1. App loads with loading screen
2. SessionManager checks Keychain for session
3. No session found → Navigate to Onboarding
4. User completes onboarding → Navigate to Auth
5. User signs up → Session stored in Keychain
6. Next app launch → Goes directly to Home

### Scenario 2: User Launches App (Returning User)
1. App loads with loading screen
2. SessionManager finds valid session in Keychain
3. Session not expired → Navigate directly to Home
4. Session expired → Navigate to Auth

### Scenario 3: User Logs Out
1. User taps logout button in Home
2. SessionManager clears Keychain
3. UserDefaults cleared
4. Navigate to Auth screen

## 🔒 Security Features

- ✅ Tokens stored in iOS Keychain (hardware-backed encryption)
- ✅ Tokens only sent over HTTPS
- ✅ Row Level Security on database
- ✅ API key validation on every request
- ✅ Automatic session expiration handling

## 🔧 How to Use in Your Screens

### In Any Screen - Access Current User Info
```swift
@EnvironmentObject var sessionManager: SessionManager

if let currentSession = sessionManager.currentSession {
    let userId = currentSession.userId
    let userName = currentSession.userName
    let userEmail = currentSession.userEmail
}
```

### Logout Example (In Home Screen)
```swift
@ObservedObject var viewModel: AuthViewModel

func logout() {
    Task {
        await viewModel.logout()
        // Navigate back to auth
    }
}
```

## 📝 Database Query Example

Once logged in, you can query user data:

```sql
SELECT * FROM profiles 
WHERE id = current_user_id()
```

The RLS policies ensure users can only see their own profile.

## ⚙️ Next Steps

1. **Verify Database Schema**: Go to Supabase dashboard → SQL Editor → Run schema script
2. **Test Login**: Use SignUpScreen to create a test account
3. **Verify Keychain Storage**: After login, session should persist across app relaunches
4. **Add Custom Endpoints**: Connect Profile, Wishlist, Map data to your backend
5. **Implement Logout UI**: Add logout button to ProfileScreen using `viewModel.logout()`

## 🐛 Troubleshooting

**Issue**: Login fails with "Configuration Missing"
- Fix: Ensure `SupabaseConfig` in `AuthEndpoints.swift` has correct URL and Anon Key

**Issue**: Session not persisting across app restarts
- Check: Verify Keychain is properly initialized
- Solution: Rebuild and try again

**Issue**: Getting CORS errors
- This is normal for Supabase - API handles it automatically

**Issue**: User can't create account
- Check: Email confirmation might be required (see Supabase email settings)
- Check: Password must be 8+ characters

## 📞 Connection Details Reference

```
Protocol: PostgreSQL
Host: db.vnqqgxyakcbkeoualauc.supabase.co
Port: 5432
Database: postgres
User: postgres
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZucXFneHlha2Nia2VvdWFsYXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NTUyNTIsImV4cCI6MjA5MTMzMTI1Mn0.UH8g9MxE6g477evC-y6-bDFi-DJ3Y9DTgcTIWrhm4c0
Project URL: https://vnqqgxyakcbkeoualauc.supabase.co
```

## ✨ You're All Set!

Your app now has production-ready authentication with:
- Secure token storage
- Persistent sessions
- Automatic session validation
- Proper logout functionality
- Database integration

Happy travels! 🧳
