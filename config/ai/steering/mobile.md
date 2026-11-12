---
title: Mobile and Cross-Platform App Steering
description: Tauri-first defaults for one shared desktop and mobile interface, native boundaries, device behavior, and releases.
applies_when:
  - Android or iOS app work
  - Shared desktop and mobile interfaces
  - Tauri or Capacitor shells and native plugins
  - Mobile navigation, lifecycle, storage, or permissions
  - Device testing or app store releases
tags:
  - mobile
  - tauri
  - android
  - ios
  - desktop
  - webview
  - rust
---

# Mobile and Cross-Platform App Steering

- Prefer Tauri 2 when desktop and mobile are equally important and share one web interface, especially with Rust application logic. Keep existing working stacks.
- Prefer Capacitor when extending a web app mainly to phones without a Rust core or equal desktop requirement. Consider Expo/React Native for phone-first apps where native controls outweigh DOM reuse; do not migrate a working Tauri app just for that preference.
- Use the [tauri-mobile skill](../skills/tauri-mobile/SKILL.md) for implementation and device verification. Check current docs and each plugin's target support before choosing dependencies.
- Keep Vite, React, plain CSS, pnpm, Zod, and the TypeScript checks for new web interfaces. Keep an existing vanilla or other framework interface; do not rewrite it merely to adopt these defaults.
- Keep one editable shared UI. Put responsive layout in shared components/styles and native operations behind small shell adapters. Adapt to available space and input capabilities; use platform branches for actual platform behavior.
- Keep reusable Rust logic independent of Tauri. Use commands for application operations and Swift/Kotlin plugins for platform APIs. Validate command arguments and file access in native code; frontend validation is not a security boundary.
- Grant only required Tauri capabilities and scopes. Keep untrusted documents separate from privileged app content; do not give remote pages native command access.
- Keep routing for meaningful screens even without an address bar. Integrate shell history, deep links, Android Back and back gestures; dismiss the active overlay before leaving its screen, and let the system handle leaving the root. Do not trap Back or indiscriminately intercept it.
- Account for safe areas and edge-to-edge system bars. Keep focused inputs and primary actions visible when the keyboard opens; test resize, scrolling and dismissal on both phone platforms.
- Use comfortably sized touch targets (aim for 44 pt on iOS and 48 dp on Android). Do not depend on hover or gestures alone; preserve mouse and keyboard interaction on desktop.
- Test screen-reader labels, focus order, text scaling, contrast and reduced motion with VoiceOver/TalkBack. Do not disable zoom to fix layout.
- Persist important edits as they happen. Restore after process death; do not depend on unload or a final pause callback. Suspend unnecessary work and recheck permissions, handles and external storage on resume.
- Make core offline workflows work after a cold launch without a development server. Choose durable storage, migrations and recovery deliberately; define conflict handling and repeat-safe writes when sync is needed. A query cache is not the source of truth for user data.
- Use TanStack Query for remote server state, not as a mandatory layer over local data. If used for local commands, configure network mode, retries, focus/reconnect refetch and invalidation explicitly; do not retry permanent local failures or block local reads on connectivity.
- Request permissions at the point of use, explain why, and handle denial, revocation and unavailable hardware. Keep secrets in platform secure storage; never embed private credentials in the app bundle.
- Treat Android WebView and iOS WKWebView as separate browser targets. Verify CSS, keyboard, scrolling, file URLs, downloads, cookies and content protocols on the oldest supported OS/WebView, not only desktop Chromium.
- Measure release builds before changing UI frameworks for size. Offline assets still incur parsing, execution and rendering costs; native libraries, media, fonts and plugins also affect install size. Report JS size, packaged/download size, installed size and cold-start timings separately, with device and build details.
- Establish app identifiers, signing ownership, protected signing credentials and version/build numbers early. Verify privacy declarations, entitlements and current store requirements before submission. Native changes need a new native build; do not assume a desktop updater covers mobile releases.
- Verify upgrades preserve user data and test signed builds through internal distribution before public release. Building an artifact does not authorize publishing it.

## Sources

- [Tauri architecture](https://v2.tauri.app/concept/architecture/), [mobile plugins](https://v2.tauri.app/develop/plugins/develop-mobile/), [capabilities](https://v2.tauri.app/security/capabilities/), [WebView versions](https://v2.tauri.app/reference/webview-versions/), and [distribution](https://v2.tauri.app/distribute/).
- [Android Back](https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture) and [state restoration](https://developer.android.com/topic/libraries/architecture/saving-states).
- [TanStack Query defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults) and [network modes](https://tanstack.com/query/latest/docs/framework/react/guides/network-mode).

Stack choices are preferences, not benchmark results. Recheck version-specific APIs and store requirements for the target project.
