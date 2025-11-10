# 🗺️ Google Maps API Setup Guide

## Current Issue

The Google Maps API key needs to be properly configured in the Google Cloud Console.

**Error**: `InvalidKeyMapError` - The API key exists but needs the Maps JavaScript API enabled.

## ✅ Steps to Fix

### 1. Go to Google Cloud Console
Open: https://console.cloud.google.com/google/maps-apis/credentials

### 2. Find Your API Key
Look for the API key: `AIzaSyClM3oua_QM_fSy_9WgnhQK6jkoN50lGTc`

### 3. Enable Required APIs
You need to enable these APIs for the key:

#### Click "Enable APIs" or go to:
https://console.cloud.google.com/apis/library

#### Enable these 3 APIs:
1. **Maps JavaScript API** ⭐ (REQUIRED for web maps)
2. **Maps SDK for Android** (for Android app)
3. **Maps SDK for iOS** (for iOS app - optional)

### 4. Configure API Key Restrictions (Recommended)

#### Application Restrictions:
- Select: **HTTP referrers (web sites)**
- Add referrer:
  - `localhost/*` (for development)
  - `127.0.0.1/*` (for development)
  - Your production domain (when deploying)

#### API Restrictions:
- Select: **Restrict key**
- Choose:
  - Maps JavaScript API
  - Maps SDK for Android
  - Geocoding API (for address lookups)

### 5. Save Changes
Click **Save** and wait 1-2 minutes for changes to propagate.

## 🧪 Test the Fix

1. Restart your Flutter app:
   ```powershell
   flutter run -d chrome
   ```

2. Log in and click the **Map** tab on home screen

3. The map should load showing:
   - Google Maps with hospitals
   - Hospital markers
   - Your current location
   - No "InvalidKeyMapError"

## 📋 Current Configuration

### Files Updated:
- ✅ `web/index.html` - Google Maps API key inserted
- ✅ `.env` - Google Maps key set correctly

### API Keys:
- **Google Maps**: `AIzaSyClM3oua_QM_fSy_9WgnhQK6jkoN50lGTc`
- **Gemini AI**: `AIzaSyCB0fj0yJovgsMjtpCY_klPnFGfDFNX52I` ✅ Working!

## ⚠️ Important Notes

### If Map Still Doesn't Work:

1. **Wait 1-2 minutes** after enabling APIs
2. **Clear browser cache**: Ctrl+Shift+Delete → Clear cache
3. **Hard refresh**: Ctrl+Shift+R
4. **Check billing**: Maps API requires billing enabled (free tier includes $200/month credit)

### Enable Billing:
If you see billing-related errors:
1. Go to: https://console.cloud.google.com/billing
2. Link a billing account (you get $200 free credit monthly)
3. Maps usage is usually well within free tier for development

## 🎯 What's Working

✅ **Gemini AI Chat** - Fully functional!  
✅ **Location Services** - Getting coordinates  
✅ **Hospital Data** - Loading from Firestore  
✅ **Book Appointment** - Complete flow working  
⏳ **Google Maps** - Needs API enabled in Cloud Console  

## 🔗 Quick Links

- **Google Cloud Console**: https://console.cloud.google.com
- **API Library**: https://console.cloud.google.com/apis/library
- **Credentials**: https://console.cloud.google.com/google/maps-apis/credentials
- **Maps JavaScript API**: https://console.cloud.google.com/apis/library/maps-backend.googleapis.com
- **Billing**: https://console.cloud.google.com/billing

---

**After enabling the APIs, the map will work perfectly!** 🗺️✨
