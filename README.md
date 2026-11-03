# Holiday Brilliant — modern Android / offline patch

Patches for the **Holiday Brilliant 1.3** light controller app (`com.toyo.holidaybrilliant`), so it
installs and runs on current Android (tested target: Android 14 behavior, minSdk 18) and works with no
internet or Google Play.

This repo contains **no original app code or assets**. You supply your own copy of the original APK
(version 1.3, versionCode 5); `build.sh` decompiles it, applies the patches and signs the result.

## Build

```sh
./build.sh path/to/HolidayBrilliant_1.3.apk                      # creates a new signing key
./build.sh path/to/HolidayBrilliant_1.3.apk my.jks alias pass    # or use your own key
```

Needs Java 11+, Python 3, curl and unzip. Downloads Apktool 2.10.0 and uber-apk-signer 1.3.0 from GitHub.

## Why the original stopped working

1. **Google Play license check (LVL).** The launcher activity asked Play to verify a purchase. The app is
   no longer sold, so the check fails, and the old LVL code also crashes on Android 5+ (implicit service
   intent). This blocked the app even on old phones.
2. **`Notification.setLatestEventInfo`** (removed in Android 6) is used by the music service → crash.
3. **targetSdk 19.** Android 14+ refuses to install apps targeting below API 23.

## What the patch changes

| Area | Change |
|---|---|
| Manifest | `SplashActivity` is the launcher; license activity and `CHECK_LICENSE` removed; targetSdk 34; `android:exported` on components; `mediaPlayback` foreground service type; modern permissions (`READ_MEDIA_AUDIO`, `POST_NOTIFICATIONS`, `BLUETOOTH_CONNECT`, `FOREGROUND_SERVICE*`), legacy ones capped with `maxSdkVersion` |
| `SplashActivity` | Requests runtime permissions on Android 6+, continues when answered |
| `MusicService` | Notifications built with `Notification.Builder` + channel; `PendingIntent.FLAG_IMMUTABLE`; stays in the foreground between tracks (Android 12+ forbids re-entering foreground from the background); catches all errors when opening a song |
| `MusicPlayerActivity` | Media query and album-art loading no longer crash on Android 10+ |
| `Compat.smali` | New helper class used by the above |

The app was already offline apart from the license check: light commands are bundled WAV files.

## How the lights are controlled (useful to know)

Every button (on/off, mode, speed, brightness) plays a 0.12 s ~20 kHz tone from `assets/signals/wav/`
over the Bluetooth audio link; the light box decodes it. **Phone media volume must be at or near maximum**
or the box won't hear commands.

## Notes

- The patched APK is signed with a different key than the original: uninstall the original first.
- Original app © its authors. This project only distributes patch tooling.
