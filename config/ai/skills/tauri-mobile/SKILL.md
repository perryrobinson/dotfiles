---
name: tauri-mobile
description: Build, adapt, debug, and verify Tauri 2 apps sharing a web interface across desktop, Android, and iOS. Use for Tauri mobile features, plugins, and device testing; not ordinary responsive websites.
---

# Tauri Mobile

Read `~/dotfiles/config/ai/steering/mobile.md` for architecture and behavior defaults; resolve the dotfiles checkout location if it differs. Keep this workflow scoped to the requested feature.

## Establish the target

- Read repository instructions, manifests, Tauri configuration, capabilities, frontend staging and relevant native plugins. Identify supported targets, minimum OS versions, pinned toolchains and existing device commands.
- Trace the affected UI call through its command and native implementation. Check every target implementation; distinguish unsupported behavior from an untested implementation. Do not infer mobile support from a plugin's desktop example.
- Use Context7 for current Tauri/library docs. Use the official [Tauri documentation index](https://v2.tauri.app/llms.txt) when retrieval is unavailable or incomplete. Read the installed version's API and platform notes before borrowing snippets.

## Implement the smallest complete path

- Reuse the shared interface and Rust logic. Keep layout improvements in the shared UI and platform operations in adapters; respect temporary upstream-copy policies rather than editing generated or mirrored files.
- Check command validation, capability scopes, cancellation, permission denial, unavailable storage and interrupted writes at the affected boundary. Keep blocking I/O off the UI thread and avoid copying large files through JSON commands when streaming or native handles fit.
- Keep platform behavior explicit: file pickers, save/share actions, Back handling and app lifecycle are not interchangeable browser events. Verify how the pinned Tauri version exposes each behavior.
- Use existing repository build/debug commands. Read the justfiles skill before inspecting recipes. Do not regenerate native projects over hand-maintained configuration without checking the repository's generation policy.

## Verify on the target

- Run focused frontend checks, Rust formatting/lint/tests and affected native builds. Browser tests cover shared UI logic; they do not verify the native bridge or installed application.
- Exercise the changed user path on an installed build. For cross-platform changes, cover a desktop target, Android and iOS; report any unavailable target explicitly. Local iOS builds require macOS/Xcode; use an existing authorized Mac or CI workflow when necessary.
- For Android, select the device explicitly with `adb -s <serial>` through RTK, collect logcat, and inspect a debug WebView through Chrome remote debugging. For iOS web content, use Safari Web Inspector on a Mac; use Xcode/device logs for native failures. Keep inspection enabled only where appropriate for debugging.
- Select relevant cases from: cold offline launch, Back/overlays, keyboard and safe areas, permission denial/revocation, background/resume, process death, external storage removal/reconnection, large content, screen readers and text scaling. Include mouse/keyboard behavior when changing shared controls.
- Measure startup and memory on release builds and real hardware when performance is at issue. Record device, OS/WebView, build mode, content and repeated-run results; separate cold launch from resume. Do not turn a minimal frontend bundle measurement into a claim about installed app size.
- Use an existing device farm for broader OS/device coverage when useful; check that it supports the required hardware scenario. A remote phone without the user's USB drive cannot prove external-drive behavior.
- Report commands, target/device details, observed outcomes and missing checks. Separate source inspection, historical evidence and fresh device results. Do not call a cross-platform feature verified from one browser preview.

## References

- [Tauri debugging](https://v2.tauri.app/develop/debug/) and [prerequisites](https://v2.tauri.app/start/prerequisites/).
- [Android adb](https://developer.android.com/tools/adb), [WebView debugging](https://developer.chrome.com/docs/devtools/remote-debugging/webviews), and [WebKit inspection](https://webkit.org/web-inspector/enabling-web-inspector/).
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab/) for device coverage; check current supported devices and test types.
