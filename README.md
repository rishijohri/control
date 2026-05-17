# control

Mindful app-interruption layer built with Flutter + Android native interception.

## Implemented foundations

- Modular Flutter architecture (`/lib/core`, `/lib/features`, `/lib/widgets`, `/lib/data`)
- Riverpod-based app selection and protection toggles
- Calming intervention screen with breathing animation + intent chips + delay gate
- Local persistence using Hive for protected apps, analytics, and focus modes
- Analytics dashboard with local weekly chart
- Focus modes and settings scaffolding
- Permission onboarding flow for accessibility / usage / battery optimization
- Native Android integration:
  - MethodChannel bridge (`control/app_interception`)
  - Accessibility service for app launch detection and loop-safe interception
  - Boot receiver for post-reboot reliability hooks

## Notes

This environment did not include the Flutter SDK binary (`flutter` command unavailable), so project code and structure were created directly.
Run locally with Flutter installed:

```bash
flutter pub get
flutter test
flutter run
```
