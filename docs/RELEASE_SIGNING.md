# Android release signing

The Android release build accepts signing values only through environment variables:

- `RELEASE_STORE_FILE`
- `RELEASE_STORE_PASSWORD`
- `RELEASE_KEY_ALIAS`
- `RELEASE_KEY_PASSWORD`

When all four are present, `android/app/build.gradle` configures the release signing config from them. When they are absent, CI may still compile a release AAB using the debug signing configuration; that artifact is for build verification only and is not a production release.

For production CI, store the four values as GitHub Actions secrets and expose them to the build step without writing them to the repository.
