# Agent Rules

## Communication
- Keep responses short and direct.
- Present plan or diff first — only act when told "approved" or equivalent.
- Never write or modify code without explicit approval from the user.

## Tech Stack
- **Language:** Dart (>=3.4)
- **Framework:** Flutter
- **State Mgmt:** provider
- **Database:** sqflite (SQLite)
- **Testing:** flutter_test

## Commands
- `flutter analyze` — static analysis / linting
- `flutter test` — run all tests
- `flutter run` — run the app

## Conventions
- Follow `flutter_lints` rules (analysis_options.yaml).
- Use `provider` for state management — no other state libs.
- Keep models under `lib/models/`, utils under `lib/utils/`, widgets under `lib/widgets/`.
- UI kit widgets live in `lib/widgets/ui_kit/`.
- Use `ponytail:` comments for deliberate simplifications.
