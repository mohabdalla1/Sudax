# Sudax — Flutter Web + Firebase

A responsive Arabic/English web portal for Sudax. It is designed to run in a modern browser on phones, tablets, and computers. This is a migration starter based on the provided React/Vite archive, not a verified production release.

## Preserved capabilities

- Firebase email/password sign-in and registration.
- Arabic/English UI toggle with RTL/LTR direction.
- Client, developer, and admin role-aware project queries.
- Client project requests written to the existing `projects` schema.
- Project status display for requested, in-progress, review, and completed states.
- Original `firestore.rules` carried over unchanged for review/testing.
- Firebase Hosting SPA rewrite targeting `build/web`.

## Requirements

- Flutter stable (Dart included)
- Firebase project with Authentication (Email/Password) and Cloud Firestore enabled
- Firebase CLI for deployment
- FlutterFire CLI recommended for config generation

## Configure Firebase

1. In Firebase Console, open the existing project used by the original starter (if one exists).
2. Enable **Authentication → Sign-in method → Email/Password**.
3. Ensure Cloud Firestore is enabled and back up/export existing data before any rule or schema changes.
4. Install the FlutterFire CLI and authenticate:
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure
   ```
5. Run `flutterfire configure` from this directory and choose your existing Firebase project. It should generate `lib/firebase_options.dart`; if it overwrites the template, keep the generated version. Do not commit private service-account credentials.
6. Verify Authentication authorized domains for your planned web domain and `localhost` during local testing.

> `lib/firebase_options.dart` currently contains placeholders. The app will not connect until it is generated/configured with your Firebase Web app values.

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

For a production build:

```bash
flutter build web --release
```

## Deploy to Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
cp .firebaserc.example .firebaserc
# Edit .firebaserc and set your real Firebase project ID
firebase deploy --only firestore:rules,hosting
```

Review `firestore.rules` and test with the Firebase Emulator Suite before deploying rules to an existing live project. The rule file was copied from the supplied React starter, not independently security-tested.

## Existing repository

The public GitHub repository `https://github.com/mohabdalla1/Sudax` currently exposes only a `README.md` on its `main` branch. No commits were made to GitHub from this workspace. This project folder/ZIP is prepared for you to review, then upload/commit to that repository.

## Current scope and known gaps

- Admin user/role management UI is not included in the source React starter, so role assignment remains a trusted Firebase Console/server-side operation.
- Developer project status editing and project updates are not implemented in this first Flutter migration pass; assigned-project viewing is preserved.
- Password reset, email verification enforcement, audit logs, file uploads, payments, and server-side validation are not included.
- No Flutter SDK is available in the creation environment, so `flutter analyze`, browser testing, and `flutter build web` have not been run. Run them locally after Firebase configuration and fix any SDK-version-specific issues before deployment.
