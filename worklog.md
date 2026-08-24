---
Task ID: 1
Agent: main
Task: Create GitHub Actions CI/CD workflows and update documentation

Work Log:
- Explored project structure: confirmed Flutter project, no android/ios dirs in repo
- Created .github/workflows/android.yml — builds APK/AAB on push to main (ubuntu-latest)
- Created .github/workflows/ios.yml — builds IPA on push to main (macos-latest, no codesign)
- Created CI_GUIDE.md — detailed instructions on using workflows, code signing, debugging
- Updated README.md — added CI/CD section, full route table, updated project structure tree
- Updated .gitignore — added Flutter-specific entries (*.freezed.dart, *.g.dart, android/, ios/, etc.)

Stage Summary:
- Android workflow: auto-build on push, manual dispatch with APK/AAB choice, artifact upload (30 days)
- iOS workflow: auto-build on push, manual dispatch, --no-codesign by default, commented code signing steps ready
- CI_GUIDE.md covers: automatic/manual triggers, downloading artifacts, APK installation, iOS code signing setup, APK vs AAB, debugging
- .gitignore now properly ignores generated code and platform directories
