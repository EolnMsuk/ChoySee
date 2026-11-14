# v1.5.5~b4

- App Plugin & global overwrite sorting: Apps and daemons now also sort to the top of the Applications list and display the grey status dot (when tagging is enabled) if Overwrite Global Tweak Configuration is enabled, or if an installed App Plugin uses custom rules, disabled injection, or global overwrite when the parent app has no configuration of its own.
- Global tweak filtering: Custom lists now hide globally disabled tweaks unless the app, daemon, or plugin has Overwrite Global Tweak Configuration enabled.
- Legacy iOS defaults: Tag Custom Apps and "Open in Choicy" Option now default to off on iOS versions older than iOS 15.

# v1.5.5~b3

- Apps and daemons with disabled tweak injection or active custom rules now sort to the top of their lists and refresh automatically when changed.
- Added **Tag Custom Apps**, which places a small grey indicator dot on the Home Screen icons of configured apps.
- Added **"Open in Choicy"** to the Home Screen 3D Touch / Haptic Touch menu, jumping directly to that app's Choicy settings without killing the app.
- Updated **Choicy > App Options** to list **Tag Custom Apps**, **"Open in Choicy" Option**, **"Launch Without Tweaks" Option**, and **"Launch With Tweaks" Option** in order. On fresh installs or resets, the first two default to on while the one-time launch options default to off.
- Improved reliability when jumping from Home Screen shortcuts into Settings, prevented duplicate menu entries, and hardened preference/list updates against crashes.
- Added native Roothide support and updated modern Rootless and Rootful packages to target iOS 15+. Older devices (iOS 10–14) are now supported via a separate Legacy Rootful build with improved 32-bit compatibility.

## Overview

The modern workflow uses SDK 16.5 and Xcode 16.4. The Legacy Rootful profile uses a prepared Xcode 11.7 toolchain, patched SDK 13.7, and a separate Clang to generate tail-call assembly.

| Profile | Firmware dependency | Mach-O slices | Debian architecture | Filename |
| --- | --- | --- | --- | --- |
| Rootless | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm64` | `Choicy_1.5.5~b3_Rootless.deb` |
| Native Roothide | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm64e` | `Choicy_1.5.5~b3_Roothide.deb` |
| Rootful | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm` | `Choicy_1.5.5~b3_Rootful.deb` |
| Legacy Rootful | `>= 10.0` | `armv7 arm64 arm64e` with old arm64e ABI and iOS 12.0 floor on that slice | `iphoneos-arm` | `Choicy_1.5.5~b3_Rootful_Legacy_iOS10.deb` |

## File inventory

### Added

| File | Reason |
| --- | --- |
| `.github/scripts/verify-package.py` | Check modern metadata, firmware, payload paths, Mach-O slices, and native Roothide linkage before labeling artifacts. Expect b3. |
| `.github/workflows/build.yml` | Build, verify, and upload the three modern schemes with pinned toolchain and development inputs. |
| `ChoicyRoot.h` | Share the native Roothide and libroot path interfaces across targets. |
| `changelog.md` | Summarize the b3 release and inventory the net changes from v1.5.4. |
| `control.legacy` | Give Legacy Rootful a separate b3 control file with the iOS 10.0 firmware minimum and the same Choicy identity and runtime dependencies. |
| `legacy_build.sh` | Validate prepared inputs and explicitly select, clean, generate, build, and verify the local Legacy Rootful profile. |
| `scripts/legacy-clang.sh` | Check the SDK Theos resolved and apply the iOS 12.0 arm64e floor to legacy compiler and link calls. |
| `scripts/package-legacy.py` | Check development inputs, package the Theos stage with legacy metadata and gzip, and publish only after payload, Mach-O, and signature verification. |

### Modified

| File | Reason |
| --- | --- |
| `.gitignore` | Ignore the legacy artifact and scratch directory. |
| `ChoicyPrefs/CHPApplicationListSubcontrollerController.m` | List configured apps first and refresh after preference changes while preserving AltList search and sections. |
| `ChoicyPrefs/CHPDaemonList.m` | Resolve Rootful and jailbreak paths through the shared wrapper and deliver observer updates on the main thread. |
| `ChoicyPrefs/CHPDaemonListController.m` | List configured daemons first and manage refresh and observer cleanup. |
| `ChoicyPrefs/CHPPackageInfo.m` | Use the shared path wrapper for package lookup. |
| `ChoicyPrefs/CHPPreferences.h` | Expose the Settings preference reload function to controllers. |
| `ChoicyPrefs/CHPProcessConfigurationListController.m` | Call the parent disappearance method and check a previously displayed row before reloading it. |
| `ChoicyPrefs/CHPRootListController.m` | Deliver main-thread preference updates, route one-use requests with a Back stack, use jailbreak paths, and refresh switches immediately after reset. |
| `ChoicyPrefs/CHPTweakList.m` | Search translated jailbreak tweak paths and retain existing fallbacks. |
| `ChoicyPrefs/Makefile` | Link native Roothide, adjust one LiteHook warning, and quote staging paths. |
| `ChoicyPrefs/Resources/Root.plist` | Identify the Applications route, add the two optional features and footer, and set the App Options order and defaults. |
| `ChoicyPrefs/entry.plist` | Give PreferenceLoader a stable `ChoicyPrefs` routing ID. |
| `ChoicySB/ChoicySB.h` | Expose the icon tag refresh function. |
| `ChoicySB/Makefile` | Link UIKit and QuartzCore for icon tags and use native Roothide libraries for that scheme. |
| `ChoicySB/SpringBoard.h` | Declare the icon, shortcut dismissal, and Settings opening interfaces. |
| `ChoicySB/SpringBoard.x` | Add icon dots and the Open in Choicy shortcut for both menu paths, translate resource paths, and honor the App Options fallbacks and saved choices. |
| `ChoicySB/Tweak.x` | Reload on the main thread in SpringBoard, validate app dictionaries, type the notification callback, and refresh icon tags. |
| `Makefile` | Export modern SDK, deployment and slices, select direct hook compilation or legacy assembly, and route legacy stage output to its isolated packager. Keep native Roothide linkage and the focused LiteHook warning adjustment. |
| `README.md` | Describe modern and legacy builds, prepared inputs, scope, and expected artifacts. |
| `Shared.h` | Declare configured-state and request interfaces, keys and routing constants, and shared jailbreak paths. |
| `Shared.m` | Check process preference dictionaries, detect configured state, and manage locked, expiring one-use requests. |
| `Tweak.c` | Use the shared jailbreak path interface and make pointer conversions and section iteration work at either pointer width. |
| `Tweak.s` | Select and check only the matching generated hook assembly, with an error for unsupported architectures. |
| `control` | Set release b3 and require iOS 15.0 for the modern packages. |
| `gen.c` | Document direct compilation and legacy assembly generation from the same hook bodies. |
| `gen_asm.sh` | Generate the legacy slices using explicit compiler, SDK, deployment, and ABI settings with fail-fast publication. |
| `layout/Library/Application Support/Choicy.bundle/en.lproj/Localizable.strings` | Supply English labels for the new options, Configured section, and App Options footer. |
| `release_build.sh` | Use a valid shell header and explicitly build all three modern schemes, including native Roothide. |
