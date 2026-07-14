# Privacy Policy for AltType

**Last Updated:** July 13, 2026

AltType processes everything on your device and collects nothing.

## Audio and Transcriptions

- AltType accesses your microphone only while you are actively dictating.
- All speech recognition runs locally on your Mac — either through Apple's on-device SpeechAnalyzer or a locally stored Whisper model.
- Audio is processed in real time and immediately discarded. It is never stored and never transmitted anywhere.
- Transcription history is kept only in local app storage on your Mac, solely so you can review and copy past dictations. You can clear it at any time from the app.

## What AltType Does Not Do

- No audio or transcripts ever leave your device
- No analytics, telemetry, or crash reporting
- No accounts, no tracking identifiers
- No third-party services receive any of your data

## Network Access

The only network activity AltType performs is downloading speech model assets:

- Apple speech model assets are downloaded and managed by macOS itself.
- Optional WhisperKit models are downloaded from Hugging Face when you choose a Whisper model, and stored locally in `~/Library/Application Support/TheTypeAlternative`.

No user data is sent in either case.

## Permissions

- **Microphone** — required to capture speech for transcription
- **Accessibility** — required to insert transcribed text into other applications and to detect the global dictation hotkey

Both permissions are used solely for these purposes.

## Changes

Changes to this policy will be published in this repository alongside the source code.
