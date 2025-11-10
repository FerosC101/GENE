# 🔑 API Key Setup Guide

## ⚠️ URGENT: Gemini API Key Leaked

Your Gemini API key was reported as leaked and has been disabled by Google for security reasons.

## 📋 Step-by-Step Fix

### 1. Get a New Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Get API Key"** or **"Create API Key"**
4. Click **"Create API key in new project"** or select an existing project
5. Copy the generated API key (starts with `AIzaSy...`)

### 2. Update Your .env File

1. Open the file: `d:\coding\flutter\gene\.env`
2. Find the line: `GEMINI_API_KEY=YOUR_NEW_GEMINI_API_KEY_HERE`
3. Replace `YOUR_NEW_GEMINI_API_KEY_HERE` with your new API key
4. **IMPORTANT**: Save the file

Example:
```env
GEMINI_API_KEY=AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Restart Your Flutter App

```powershell
# Stop the current app (press 'q' in terminal or Ctrl+C)
# Then run again:
flutter run -d chrome
```

## 🔒 Security Best Practices

### ✅ DO:
- Keep your `.env` file in `.gitignore` (already configured)
- Never commit API keys to Git
- Rotate keys regularly
- Use environment variables for sensitive data

### ❌ DON'T:
- Share API keys in screenshots
- Commit `.env` file to public repositories
- Use the same key across multiple projects
- Hardcode API keys in source code

## 🎯 What's Fixed

### 1. ✅ Firestore Permissions
- **Fixed**: Chat messages can now be saved
- **Deployed**: New security rules to Firebase
- **Result**: No more `permission-denied` errors

### 2. ✅ Booking Features Added
- **Home Screen**: New "Book Appointment" card (green button)
- **Quick Actions**: "Book appointment" chip now functional
- **AI Chat**: "Book appointment" button navigates to hospital list
- **Navigation**: All booking paths lead to hospital selection → booking screen

## 🚀 Testing After Fix

Once you've updated the API key:

### Test AI Chat:
1. Log in as a patient
2. Click the AI Chat tab
3. Click "Book appointment" quick action
4. Should navigate to hospital list
5. Select a hospital → Click "Book Appointment"

### Test Home Screen:
1. From patient home screen
2. Click the green "Book Appointment" card
3. Should open hospital list
4. Select hospital → Book appointment

### Test AI Conversation:
1. Open AI Chat
2. Type: "I want to book an appointment"
3. Should get helpful response and booking guidance
4. No more API key errors

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Firestore Rules | ✅ Deployed | Chat messages can be saved |
| Booking UI | ✅ Added | Green card on home screen |
| AI Navigation | ✅ Working | Routes to hospital list |
| Quick Actions | ✅ Functional | All chips have tap handlers |
| API Key | ⚠️ Needs Update | Replace in .env file |

## 🆘 Troubleshooting

### Still seeing "API key leaked" error?
1. Make sure you replaced the key in `.env`
2. Restart the Flutter app completely (quit and run again)
3. Try hot restart: press `R` in terminal
4. Clear browser cache if running on web

### Chat messages not saving?
1. Check Firebase Console: [Firestore Rules](https://console.firebase.google.com/project/app-dev-4768b/firestore/rules)
2. Verify rules are deployed (check timestamp)
3. Make sure user is logged in
4. Check browser console for error details

### Booking not working?
1. Make sure you're logged in as a patient
2. Check that hospitals exist in Firestore
3. Verify doctors have schedules set up
4. Check appointment_repository for any errors

## 📞 Need Help?

If you continue experiencing issues:

1. **Check Firebase Console**: https://console.firebase.google.com/project/app-dev-4768b
2. **View Firestore Data**: Check if hospitals and users exist
3. **Check Logs**: Look at the terminal output for specific errors
4. **Test Authentication**: Make sure login works first

---

**Last Updated**: November 11, 2025  
**Status**: Firestore rules deployed ✅, API key needs replacement ⚠️
