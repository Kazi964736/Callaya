# Call Aaya 📞

A fun fake-call app with original desi characters — Pishi-ma, Boss Babu, Tiffin Dada,
Cricket Chacha, Dadu and Robo Rinku. Pick a caller, pick a time, lock your phone,
and it rings with a full-screen incoming call. Answer it and the character talks
(Bengali, Hindi or English, using the phone's built-in voice).

All characters, lines and the ringtone are original — no real people or copyrighted memes.

## Build an APK without a computer (Codemagic)

1. Create a free GitHub account and a new repository, then upload everything in this folder.
2. Sign up at codemagic.io with GitHub and add the repository.
3. Start the **"Call Aaya – test APK"** workflow (it reads `codemagic.yaml`).
4. When it finishes (about 10 minutes), download the `.apk` from the build page and install it on your phone.

## Build on a computer

Needs Flutter 3.27 or newer.

```
flutter create --org com.callaaya --platforms android --project-name call_aaya .
rm -f test/widget_test.dart      # sample test from flutter create; not used here
python3 tool/prepare_android.py
flutter pub get
flutter run            # with a phone connected, or
flutter build apk      # makes build/app/outputs/flutter-apk/app-release.apk
```

`flutter create` only adds the missing Android files; it keeps `lib/`, `assets/` and the
custom `AndroidManifest.xml`.

## First-run test checklist

- Allow notifications, "Alarms & reminders" and full-screen notifications when asked.
- Schedule a 10-second call, lock the phone: it should light up and ring.
- If the call only shows as a notification instead of full screen, open the app's settings
  and allow full-screen notifications (Android 14+ asks for this separately).
- If a character speaks in English instead of Bengali/Hindi, install that language voice in
  the phone's Text-to-speech settings (Google Speech Services).

## Before publishing on Play Store

- Change the app id `com.callaaya.call_aaya` if you want your own.
- Set up a release signing key (the test APK uses a debug key).
- In Play Console, declare the full-screen intent and exact-alarm permissions and explain
  they are used to show the scheduled fake call. Google may restrict full-screen intents to
  calling/alarm apps — check the current policy before submitting.
