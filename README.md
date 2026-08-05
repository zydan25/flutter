# Dynamic Flutter App

This project is a Flutter shell that loads its UI from `https://flutter.alattab.site/api/app-config`.

## What it already supports
- Remote configuration sync on launch
- Manual sync button
- Local cache fallback with SharedPreferences
- Optional login screen
- Dynamic screens
- Dynamic components:
  - text
  - title
  - button
  - outlined_button
  - card_button
  - input
  - divider
  - spacer
  - image
- Actions:
  - navigate
  - sync
  - logout
  - open_url

## Expected API response
```json
{
  "app_name": "My App",
  "login_enabled": true,
  "home_screen": "home",
  "version": 1,
  "theme_mode": "system",
  "screens": [
    {
      "name": "home",
      "title": "الرئيسية",
      "description": "أهلاً بك",
      "components": [
        {
          "type": "button",
          "text": "اذهب إلى التفاصيل",
          "action": {
            "type": "navigate",
            "target": "details"
          }
        }
      ]
    }
  ]
}
```

## Notes
- The Android folder is included so this repository can be used by APK build platforms.
- If a platform regenerates Android scaffolding, keep this repository root and build from it.
- Flutter SDK is required on the build platform.
