# NDAX AI

Flutter Android client for a locally running Ollama server.

## Requirements
- Flutter stable SDK
- Android SDK / Android Studio for local Android builds
- Ollama server reachable from the Android device

## First-time project setup
This starter contains the Dart app source and Android manifest customization. Generate the remaining Flutter Android platform files once:
```bash
flutter create --platforms=android .
```
Then ensure `android/app/src/main/AndroidManifest.xml` includes INTERNET permission and `android:usesCleartextTraffic="true"` (the supplied manifest already contains these settings; check it after generation).

## Run
```bash
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## Ollama
The app calls:
- `GET /api/tags`
- `POST /api/chat`

Default server URL: `http://127.0.0.1:11434`

Download a model in the Ollama environment, for example:
```bash
ollama pull qwen3:4b
ollama list
```

Important Android networking note:
`127.0.0.1` means the Android device itself. This works only if Ollama's server is actually reachable on the device loopback interface. Running Ollama inside a Linux PRoot container may have networking/process compatibility limitations. Verify the API from the Android environment before assuming the Flutter app can connect. If Ollama runs on a different computer, set the app's Ollama URL to that computer's LAN IP and configure Ollama to listen on the LAN, with appropriate firewall protection.

## Private GitHub repository
Create a **Private** repository named `ndax-ai`, then:
```bash
git init
git add .
git commit -m "Initial NDAX AI Flutter app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/ndax-ai.git
git push -u origin main
```

Do not commit GitHub tokens, passwords, API keys, or private data.

## GitHub Actions
The included workflow generates Android platform files, builds a release APK, and uploads it as a workflow artifact.

## Current scope
This starter includes chat, model listing, editable Ollama URL, system prompt, temperature setting, and local SQLite chat history. It does not install or bundle Ollama/model weights into the APK.

## Claude API
Pilih **Claude API** di menu Pengaturan, lalu masukkan API key Anda (dari console.anthropic.com). Model yang tersedia: `claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5`. Key disimpan lokal di perangkat dan tidak ikut di repository. Untuk distribusi publik, sebaiknya gunakan backend proxy agar key tidak tersimpan di APK.
