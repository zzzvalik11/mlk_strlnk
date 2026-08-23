# Worklog

---
## Task 1 — Auth session management enhancements

**Date:** 2025-07-09
**Agent:** Dart code agent

### Changes

1. **`lib/core/constants/app_constants.dart`** — Added new auth-related constants:
   - `tokenExpiryKey`, `authMethodKey`, `firstLoginDoneKey`, `isLockedKey` storage keys
   - `tokenValidity` duration (365 days)

2. **`lib/data/local/storage_service.dart`** — Added `getBool`/`setBool` and `getInt`/`setInt` methods to the StorageService wrapper, enabling boolean and integer persistence via SharedPreferences.

3. **`lib/data/datasources/local/user_local_source.dart`** — Enhanced UserLocalSource with:
   - `AuthMethod` enum (pin, biometric) for quick re-login choice
   - Token expiry management: `saveTokenExpiry`, `getTokenExpiry`, `isTokenValid`
   - Auth method persistence: `saveAuthMethod`, `getAuthMethod`
   - First login flag: `markFirstLoginDone`, `isFirstLoginDone`
   - Lock state: `setLocked`, `isLocked`
   - Expanded `clearSession` to clean all new keys

4. **`lib/presentation/providers/auth_provider.dart`** — Updated AuthNotifier with:
   - `_checkAuth` now validates token expiry (365 days); clears session if expired
   - `login` saves token expiry (now + 365 days) on success
   - New `authenticateWithPin` method for quick PIN-only re-login (validates cached user PIN + token validity)
   - New `authenticateWithBiometric` method for biometric re-login (validates token validity; actual biometric prompt handled at UI level)
   - Added `AppConstants` import for `tokenValidity` duration

5. **`pubspec.yaml`** — Added `local_auth: ^2.3.0` dependency for biometric authentication support.

---
## Task 2 — Quick login, auth method selection & settings screens

**Date:** 2025-07-09
**Agent:** Dart code agent (Task ID: 2)

### Changes

1. **`lib/presentation/screens/login/quick_login_screen.dart`** (NEW) — Quick re-login screen for returning users with valid tokens.
   - `ConsumerStatefulWidget` that reads stored `AuthMethod` and shows either a PIN-only input or biometric prompt.
   - Auto-triggers `local_auth` biometric scan on init when method is `AuthMethod.biometric`.
   - PIN mode: centered 6-digit `TextField` with submit button; calls `authenticateWithPin`.
   - Biometric mode: large fingerprint icon button; calls `authenticateWithBiometric` after hardware auth succeeds.
   - Listens to `authProvider` for success/error navigation.
   - Error mapping for biometric lockout with Russian messages.
   - Fallback link to full login (`Routes.login`) in biometric mode.

2. **`lib/presentation/screens/login/auth_method_selection_screen.dart`** (NEW) — One-time screen shown after first successful full login.
   - Two option cards: ПИН-код and Отпечаток пальца.
   - On selection: saves `AuthMethod` and marks first login done via `UserLocalSource`, then navigates to home.
   - "Выбрать позже" skip button goes directly to home.

3. **`lib/presentation/screens/settings/settings_screen.dart`** (NEW) — Settings screen for auth method management.
   - Allows switching between PIN and biometric quick-login methods.
   - Shows selected method with check icon, calls `saveAuthMethod` on change.
   - Logout button that calls `authProvider.notifier.logout()` and pops.
   - App info footer (Starlink v1.0.0).

4. **`lib/presentation/screens/login/login_view_model.dart`** (MODIFIED) — Updated login flow for first-login detection.
   - Added `LoginFormNeedsMethodSelection` sealed state class.
   - `LoginFormSuccess` now has `isFirstLogin` field (defaults to false).
   - `login()` method checks `isFirstLoginDone()` after successful auth; if first login, marks done and emits `LoginFormNeedsMethodSelection`.
   - Added `UserLocalSource` import.

5. **`lib/presentation/screens/login/login_screen.dart`** (MODIFIED) — Updated `ref.listen` block.
   - Now handles `LoginFormNeedsMethodSelection` by navigating to `Routes.authMethodSelection`.
   - `Routes.authMethodSelection` will be added to `routes.dart` by another agent.

### Notes
- All three new screens follow the established design system: `AppTheme.orange50` background, gradient logo, `AppTheme.screenPadding`, `ConstrainedBox(maxWidth: 430)`.
- Settings screen directory was created (`lib/presentation/screens/settings/`).

---
## Task 3 — Routes, lock overlay, services screen & router updates

**Date:** 2025-07-09
**Agent:** Dart code agent (Task ID: 3)

### Changes

1. **`lib/core/constants/routes.dart`** (MODIFIED) — Added new route constants:
   - `quickLogin = '/quick_login'`
   - `authMethodSelection = '/auth_method_selection'`
   - `settings = '/settings'`
   - `services = '/services'`

2. **`lib/presentation/screens/home/home_view_model.dart`** (MODIFIED) — Enhanced with lock state:
   - Added `UserLocalSource` import.
   - `HomeLoaded` now has `isLocked` field (defaults to false) and `copyWith({bool? isLocked})` method.
   - `loadDashboard()` reads initial lock state from `userLocalSourceProvider`.
   - New `toggleLock()` method: toggles lock via `localSource.setLocked()` and updates state via `copyWith`.

3. **`lib/presentation/screens/home/home_screen.dart`** (MODIFIED) — Three additions:
   - **Lock icon button** in `_buildAppBar`: between Settings and Logout icons. Shows `Icons.lock_open_rounded` (gray400) when unlocked, `Icons.lock_rounded` (orange500) when locked. Calls `toggleLock()` on tap.
   - **Services section tappable**: "Активные услуги" header + services cards wrapped in a `GestureDetector` navigating to `Routes.services` on tap. Added chevron-right icon after the title.
   - **Lock overlay**: When `homeState.isLocked` is true, a `Positioned.fill` semi-transparent dark overlay (75% opacity) covers the entire screen with a centered lock icon, "Приложение заблокировано" message, and a "Разблокировать" button that calls `toggleLock()`.
   - Settings icon now navigates to `Routes.settings` on tap.

4. **`lib/presentation/screens/services/services_screen.dart`** (NEW) — Service plans/tariffs browser:
   - `ServicePlan` data class with id, name, category, cost, description, isMain, features.
   - Two tabs: "Основные" (3 internet plans) and "Дополнительные" (IPTV, cloud PBX).
   - Current plan highlighted with orange border and "Активен" badge.
   - Tapping a non-current plan shows confirmation dialog; confirm shows a snackbar (mock).
   - Uses `AppTheme` design tokens throughout.

5. **`lib/presentation/router/app_router.dart`** (MODIFIED) — Extended routing:
   - Added imports for `QuickLoginScreen`, `AuthMethodSelectionScreen`, `SettingsScreen`, `ServicesScreen`.
   - Updated `redirect` logic: `quickLogin` and `authMethodSelection` are now public routes (no auth required), alongside `support`.
   - Added 4 new `GoRoute` entries: `Routes.quickLogin`, `Routes.authMethodSelection`, `Routes.settings`, `Routes.services`.

### Notes
- All changes are consistent with existing codebase patterns: Riverpod, GoRouter, AppTheme, sealed class state management.
- The lock overlay uses a `Stack` wrapping the existing `RefreshIndicator` + `CustomScrollView`.
