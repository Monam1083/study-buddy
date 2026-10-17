# Study Buddy

**Snap a page. Learn it.**

Study Buddy turns a photo of study material into a step-by-step explanation, a quiz, and flashcards. It is built for the **Best Use of Gemma 4** prize at Hacktoberfest Hack Day Lahore x AWS Student Builder Group (Virtual University of Pakistan).

Demo video: _add your video link here_

## What it does

A student photographs a textbook page, handwritten notes, or a diagram. **Gemma 4** reads the image directly and returns structured study material:

- **Step-by-step explanation** of what is on the page
- **5-question multiple-choice quiz** with live scoring and an explanation for every answer
- **Flip flashcards** to swipe through and revise
- **Deep explain mode**, which turns on Gemma 4's thinking mode for math and logic-heavy pages

If a photo is blurry or unreadable, the model says so instead of guessing, and the app asks the student to retake it.

## Why Gemma 4

The whole app depends on Gemma 4's multimodal image understanding. There is no separate OCR step and no hand-written parsing rules. One request carries the image and a tutor system prompt, and Gemma returns JSON that the Flutter app renders directly.

Gemma is open-weight and lightweight, so a tool like this stays affordable for students and could later be self-hosted or run locally.

## How it works

```
Flutter app (pick + resize image)
        |
        v
Gemini API  ->  gemma-4-31b-it  (image + system prompt)
        |
        v
Structured JSON (topic, steps, quiz, flashcards)
        |
        v
Explanation, Quiz and Flashcards screens
```

- The system prompt tells the model to act as a study tutor, use only what is visible in the image, and return JSON only.
- Images are resized to 1024px wide before upload to keep responses fast.
- If the model returns malformed JSON, the app retries once before showing an error.

## Tech stack

- Flutter and Dart (Material 3)
- Gemma 4 (`gemma-4-31b-it`) through the Gemini API
- `image_picker` and `http`

## Project structure

```
lib/
  main.dart
  models/study_result.dart
  services/gemma_service.dart
  screens/home_screen.dart
  screens/result_screen.dart
```

## Run it locally

You need Flutter installed and a Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey).

1. Clone the repo and install packages:
   ```
   git clone https://github.com/Monam1083/study-buddy.git
   cd study-buddy
   flutter pub get
   ```
2. Create a file named `.env` in the project root with one line (no quotes):
   ```
   GEMINI_KEY=your_api_key_here
   ```
3. Run the app:
   ```
   flutter run -d chrome --dart-define-from-file=.env
   ```
   Or pass the key directly:
   ```
   flutter run -d chrome --dart-define=GEMINI_KEY=your_api_key_here
   ```

On web, use **Choose from gallery**, since the camera button opens a file picker in most desktop browsers. Restart the app after changing the key, because hot reload does not pick up new `--dart-define` values.

### Android and iOS

- **Android release builds:** add `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml`.
- **iOS:** add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.

## API key safety

No API key is included in this repository. `.env` and `.vscode` are listed in `.gitignore`. The key is read at build time with `String.fromEnvironment('GEMINI_KEY')`.

This app calls the Gemini API directly from the client, which is fine for local use and demos. A public deployment should route requests through a small backend that holds the key.

## Possible next steps

- Save decks and flashcards per user
- Urdu and Roman Urdu explanations
- Spaced-repetition review for flashcards
- Option to run a local Gemma model for offline use

## License

Released under the [MIT License](LICENSE).
