# Environment Setup

## API Keys Configuration

This project uses environment variables and configuration files to secure API keys. **NO API keys are stored in the repository.**

### 1. Create `.env` file

Copy the `.env.example` file to create your own `.env` file:

```bash
cp .env.example .env
```

### 2. Add Your API Keys to `.env`

Edit the `.env` file and add your actual API keys:

```properties
GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
GEMINI_API_KEY=your_actual_gemini_api_key
```

### 3. Configure Android (Google Maps)

Edit `android/local.properties` and add your Google Maps API key:

```properties
GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
```

Or copy from the example:
```bash
cp android/local.properties.example android/local.properties
```

### 4. Configure Web (Google Maps)

Edit `web/index.html` and replace `YOUR_API_KEY_HERE` with your actual API key:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY"></script>
```

### 5. Configure Firebase

#### Android
Copy the example file and add your Firebase configuration:
```bash
cp android/app/google-services.json.example android/app/google-services.json
```

Then download your actual `google-services.json` from Firebase Console and replace the example file.

#### iOS
Copy the example file and add your Firebase configuration:
```bash
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

Then download your actual `GoogleService-Info.plist` from Firebase Console and replace the example file.

### 3. Get API Keys

#### Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable **Maps SDK for Android** and **Maps JavaScript API**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy the API key

#### Gemini AI API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Copy the API key

### 4. Platform-Specific Configuration

#### Android
The AndroidManifest.xml uses the API key from `.env` file automatically through the build system.

#### Web
For web builds, you need to update `web/index.html` manually with your API key:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
```

> **Note**: For production, consider using environment-specific configuration or server-side key management.

### 5. Security Notes

- ✅ The `.env` file is added to `.gitignore` and won't be committed
- ✅ Never commit API keys to version control
- ✅ Use different API keys for development and production
- ✅ Restrict API keys in Google Cloud Console to your app's package name/domain

### 6. Install Dependencies

After setting up the `.env` file, run:

```bash
flutter pub get
```

### 7. Run the App

```bash
# For web
flutter run -d chrome

# For Android
flutter run

# For iOS
flutter run
```

## Troubleshooting

### Environment variables not loading
- Make sure `.env` file is in the root directory
- Check that `.env` is listed in `pubspec.yaml` under assets
- Run `flutter pub get` after creating `.env`
- Restart your app completely (hot reload won't work for .env changes)

### API key errors
- Verify the API key is correct in `.env` file
- Check that the API is enabled in Google Cloud Console
- Ensure API key restrictions match your app configuration
