<img width="1280" alt="Image" src="https://github.com/user-attachments/assets/33f8efd0-7bf1-478a-98e9-e8761f4a9623" />

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

This overview covers the net changes in the forked **v1.5.5~b4** project compared to `Choicy 1.5.4`.

### Behavior and compatibility

| Area | Current behavior compared with v1.5.4 |
| --- | --- |
| Applications ordering | A new alphabetical **Configured** section includes apps with disabled injection, enabled custom configuration or an active global override, either in the app or any installed App Plugin. AltList search, ordinary sections and row identities are preserved. |
| Applications status | Keep the app's own nonempty status. Otherwise, use installed plugins with priority **Tweaks Disabled > Custom > Global Overwrite**. An override qualifies only while at least one valid tweak name is disabled globally; inactive saved lists do not qualify. |
| Daemon ordering and previews | Configured processes appear first, including active global overrides. Daemon and individual plugin previews keep their direct-process behavior and validate dictionaries and Boolean flags. |
| Home Screen dots | **Tag Custom Apps** adds a small grey dot at the icon's bottom-right. The app's own configured settings qualify, including an active override; installed plugins qualify through disabled injection or custom configuration. A plugin's override alone does **not** qualify the parent for a dot. |
| Home Screen shortcuts | **Choicy Settings** opens the selected app's settings without changing its injection rules or terminating it. Both menu implementations preserve existing shortcut order, remove duplicate Choicy entries and place Settings before the applicable one-time launch option. |
| Settings navigation | Navigation waits for menu dismissal and builds a Back path through Applications and Choicy. Separate, locked one-use requests expire after 15 seconds; newer selections supersede older requests. |
| App Options defaults | Tag Custom Apps and Choicy Settings default to on on iOS 15+, and off on older systems. Both one-time launch options default to off. Explicit saved choices are retained; reset reloads the visible defaults immediately. |
| Custom tweak lists | Globally disabled tweaks are hidden unless that specific app, daemon or plugin enables its own override. Saved Allow/Deny selections are retained, and lists rebuild after preference changes or returning to the page. |
| Refresh and ownership | Preference/reset updates refresh lists and dots. Plugin ownership comes from the installed app's PlugInKit and VPN collections, with cache invalidation on app/plugin lifecycle events, Applications visits, foreground activation and icon rebinding. Uninstalled preference entries and similar bundle-ID prefixes do not establish ownership. |

Existing preference paths, process rule keys, package identity and migration version remain compatible. The two new App Options keys control presentation; Settings navigation uses a separate request file. No preference deletion, reset or migration is required to upgrade. The injection code changes concern jailbreak paths and pointer-width compatibility; the existing one-time launch mechanism remains in place.

### Expected b4 packages

These names and requirements follow the current control files, Makefiles and package verification scripts. Modern workflow outputs go to `artifacts/`; the separately selected Legacy Rootful build writes to `artifacts/legacy/`.

| Profile | Firmware dependency | Mach-O slices | Debian architecture | Expected filename |
| --- | --- | --- | --- | --- |
| Rootless | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm64` | `Choicy_1.5.5~b4_Rootless.deb` |
| Native Roothide | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm64e` | `Choicy_1.5.5~b4_Roothide.deb` |
| Modern Rootful | `>= 15.0` | `arm64 arm64e` | `iphoneos-arm` | `Choicy_1.5.5~b4_Rootful.deb` |
| Legacy Rootful | `>= 10.0` | `armv7 arm64 arm64e`; old arm64e ABI with an iOS 12.0 slice minimum | `iphoneos-arm` | `Choicy_1.5.5~b4_Rootful_Legacy_iOS10.deb` |

All profiles retain `com.opa334.choicy` and require MobileSubstrate, AltList `>= 1.0.4` and PreferenceLoader. In v1.5.4, Rootless already targeted iOS 15.0; the other build path targeted iOS 8.0. Modern Rootful now starts at iOS 15.0, while the explicit legacy profile starts at iOS 10.0 and does not restore the iOS 8.0 target.

| Build path | Toolchain and inputs | Packaging checks |
| --- | --- | --- |
| Modern workflow | Manual three-profile matrix on `macos-15-intel`, Xcode 16.4 and patched SDK 16.5. Pins scheme-specific Theos, AltList 1.0.11 and XPC headers; uses supplied vendored dependencies or pinned fallbacks. Compiles `gen.c` directly. | Checks b4 identity/version, firmware dependency, scheme-specific payload paths, all source localizations, exact `arm64 arm64e` slices and native Roothide linkage before labeling/uploading each artifact. Restores maintainer-script executable permissions for website uploads. |
| Legacy Rootful | Separate prepared macOS host with Xcode 11.7, patched SDK 13.7, matching development libraries and a separate musttail-capable assembly generator. Uses the old arm64e ABI and its iOS 12.0 minimum. No legacy job is included in the modern workflow. | Preflights headers/libraries, then checks Rootful paths, root ownership, executable maintainer scripts, gzip archives, metadata, slices, deployment/SDK versions, linkage and signatures before publishing locally. |

`release_build.sh` is a separate local helper for the three modern schemes using a prepared RootHide Theos checkout; workflow artifact verification and naming are handled by `.github/scripts/verify-package.py`.

### File inventory

File paths are relative to the project root. Brace notation such as `Name.{c,h}` covers both named files. The grouped counts below account for every added or modified file.

#### Added project and build files — 8

| File | Purpose |
| --- | --- |
| `.github/scripts/verify-package.py` | Verify b4 metadata, payload paths, slices and native Roothide linkage before naming modern artifacts. |
| `.github/workflows/build.yml` | Provision pinned inputs, build and verify three modern schemes, and upload their packages. |
| `ChoicyRoot.h` | Select native Roothide path mapping or the existing libroot interface. |
| `changelog.md` | Record release notes, expected packages and the complete local v1.5.4 comparison. |
| `control.legacy` | Define b4 Legacy Rootful metadata with an iOS 10.0 firmware requirement. |
| `legacy_build.sh` | Validate prepared tools and explicitly clean, generate, build and package Legacy Rootful. |
| `scripts/legacy-clang.sh` | Check the resolved SDK and apply the arm64e iOS 12.0 floor during compilation/linking. |
| `scripts/package-legacy.py` | Preflight development inputs and package/verify the legacy Rootful stage before publication. |

#### Modified files — 30

| File | Change |
| --- | --- |
| `.gitignore` | Ignore isolated legacy build artifacts. |
| `ChoicyPrefs/CHPApplicationListSubcontrollerController.m` | Add configured-first ordering, plugin-aware status/override sorting and refreshes while preserving AltList search and navigation. |
| `ChoicyPrefs/CHPDaemonList.m` | Use shared jailbreak paths and deliver observer enumeration/updates on the main queue. |
| `ChoicyPrefs/CHPDaemonListController.m` | Prioritize configured processes, refresh on preference/daemon updates and clean up observers. |
| `ChoicyPrefs/CHPListController.m` | Use validated process flags and shared active-override detection for direct previews. |
| `ChoicyPrefs/CHPPackageInfo.m` | Use common Rootful/Rootless/Roothide path mapping for package lookup. |
| `ChoicyPrefs/CHPPreferences.h` | Expose preference reloading to Settings controllers. |
| `ChoicyPrefs/CHPProcessConfigurationListController.h` | Track global filtering and coalesced preference refreshes; remove the obsolete section index. |
| `ChoicyPrefs/CHPProcessConfigurationListController.m` | Filter by each process's own override, retain saved lists and rebuild safely as settings change. |
| `ChoicyPrefs/CHPRootListController.m` | Apply OS-dependent defaults, refresh/reset preferences immediately and route one-use requests with the correct Back stack. |
| `ChoicyPrefs/CHPTweakList.m` | Search translated tweak directories while retaining raw Rootful and `/var/jb` fallbacks. |
| `ChoicyPrefs/Makefile` | Link native Roothide, limit one LiteHook warning adjustment and quote staging paths. |
| `ChoicyPrefs/Resources/Root.plist` | Identify the Applications route and add/reorder App Options, defaults and help text. |
| `ChoicyPrefs/entry.plist` | Give PreferenceLoader a stable Choicy settings route ID. |
| `ChoicySB/ChoicySB.h` | Expose icon-tag refreshes. |
| `ChoicySB/Makefile` | Link UIKit/QuartzCore and native Roothide for the matching scheme. |
| `ChoicySB/SpringBoard.h` | Declare icon lookup/layout, menu dismissal and Settings-opening interfaces. |
| `ChoicySB/SpringBoard.x` | Add live icon dots and Choicy Settings navigation; deduplicate both shortcut menu paths and honor saved/default options. |
| `ChoicySB/Tweak.x` | Reload safely on SpringBoard's main thread, validate app changes and refresh ownership/dots, including first writes and reset. |
| `Makefile` | Separate modern direct-hook and legacy assembly builds, enforce targets/slices, link Roothide and isolate legacy packaging. |
| `README.md` | Rebrand as ChoySee and document features, installation, legacy builds and credits. |
| `Shared.h` | Declare defaults, validated configuration/ownership helpers, new presentation keys and Settings request interfaces. |
| `Shared.m` | Validate settings, resolve/cache installed plugins, centralize defaults/configured state and lock/expire one-use navigation requests. |
| `Tweak.c` | Use shared jailbreak paths and pointer-width-correct casts and pointer-table iteration. |
| `Tweak.s` | Select/check only the current architecture's generated legacy assembly and reject unsupported targets. |
| `control` | Set version 1.5.5~b4 and the modern iOS 15.0 firmware requirement. |
| `gen.c` | Document modern direct compilation and legacy assembly generation; hook bodies are unchanged. |
| `gen_asm.sh` | Generate all legacy slices with explicit SDK/minimums/old ABI; publish only after generation succeeds. |
| `layout/Library/Application Support/Choicy.bundle/en.lproj/Localizable.strings` | Add English Configured, Tag Custom Apps, Choicy Settings and App Options help text. |
| `release_build.sh` | Explicitly build Rootless, native Roothide and modern Rootful; remove the forced Xcode 11 path. |

#### Added vendored dependency files — 47

The v1.5.4 comparison copy contains no files in these dependency folders. Current copies include source, headers, licenses and upstream READMEs; `.gitmodules` itself is unchanged. `external/SOURCES.md` records LiteHook revision `0d9d17afc011d2a8dfe67a4f7803ff99143d0f0d` and ChOma revision `2fcc1fc51f6eb778756ccdee3c809bf83a767996`, archive hashes and the included subsets.

| File(s) | Purpose |
| --- | --- |
| `external/SOURCES.md` | Record dependency provenance, archive hashes, included files and website-upload layout. |
| `external/litehook/{LICENSE,README.md}` | Retain upstream license and usage documentation. |
| `external/litehook/src/litehook.{c,h}` | Supply symbol lookup, function hooks and symbol rebinding. |
| `external/litehook/external/include/{dyld_cache_format,fixup-chains}.h` | Supply dyld cache and chained-fixup structures. |
| `external/ChOma/{LICENSE,README.md}` | Retain upstream license and usage documentation. |
| `external/ChOma/src/Base64.{c,h}` | Base64 encoding helpers. |
| `external/ChOma/src/BufferedStream.{c,h}` | Buffer-backed stream implementation. |
| `external/ChOma/src/CSBlob.{c,h}` | Code-signature blob handling. |
| `external/ChOma/src/CachePatching.h` | dyld shared-cache patch structures. |
| `external/ChOma/src/CodeDirectory.{c,h}` | CodeDirectory parsing and hashing. |
| `external/ChOma/src/DER.{c,h}` | DER encoding helpers. |
| `external/ChOma/src/DyldSharedCache.{c,h}` | dyld shared-cache parsing. |
| `external/ChOma/src/Entitlements.{c,h}` | XML and DER entitlement blobs. |
| `external/ChOma/src/Fat.{c,h}` | Universal Mach-O slice handling. |
| `external/ChOma/src/FileStream.{c,h}` | File-backed stream implementation. |
| `external/ChOma/src/Host.{c,h}` | Host CPU and preferred-slice selection. |
| `external/ChOma/src/MachO.{c,h}` | Mach-O parsing and manipulation. |
| `external/ChOma/src/MachOByteOrder.h` | Mach-O byte-order conversions. |
| `external/ChOma/src/MachOLoadCommand.{c,h}` | Mach-O load-command handling. |
| `external/ChOma/src/MemoryStream.{c,h}` | Generic memory-stream interface and operations. |
| `external/ChOma/src/PatchFinder.{c,h}` | Binary sections and pattern searches. |
| `external/ChOma/src/PatchFinder_arm64.{c,h}` | ARM64 patch-finding helpers. |
| `external/ChOma/src/Util.{c,h}` | Shared memory, alignment and string utilities. |
| `external/ChOma/src/arm64.{c,h}` | ARM64 instruction helpers. |
| `external/ChOma/src/dyld_cache_format.h` | dyld shared-cache format structures. |
| `external/ChOma/src/fixup-chains.h` | dyld chained-fixup structures. |

#### Added stored artifacts — 8

| File(s) | Contents |
| --- | --- |
| `debs/Choicy_1.5.5~b3_Rootful.deb` | Stored b3 Rootful package; metadata reports `iphoneos-arm` and iOS 15.0+. |
| `debs/Choicy_1.5.5~b3_Roothide.deb` | Stored b3 Roothide package; metadata reports `iphoneos-arm64e` and iOS 15.0+. |
| `debs/Choicy_1.5.5~b3_Rootless.deb` | Stored b3 Rootless package; metadata reports `iphoneos-arm64` and iOS 15.0+. |
| `screenshots/{1SS,2SS,3SS,4SS,main}.PNG` | Five project screenshots. |
