# ChoySee changelog

## 2.0.4

- Added a Sileo package listing with the ChoySee icon, a header banner, and six screenshots you can swipe through horizontally. The Changelog tab includes the full release history.

## 2.0.3

- Replaced the attribution below Reset Preferences with a centered footer showing the installed ChoySee version, the device’s iOS version, and the jailbreak environment.

## 2.0.2

- Changed the Donate title in OTHER to iOS system green.

## 2.0.1

- Aligned the five OTHER titles on one leading edge and centered each title vertically in its row. Moved the Updates glyph into the shared icon column.
- Matched NetShield2's white-backed GitHub mark and orange Donate coin. Donate uses the `dollarsign.circle.fill` system symbol on iOS 13 and later, with a bundled orange coin for iOS 10-12 and whenever the symbol is unavailable.
- Shortened the root footer to one line reading `ChoySee by EolnMsuk`.

## 2.0.0

Changes since Choicy 1.5.4.

### Installation and compatibility

- Renamed the tweak and its Settings page to **ChoySee** and assigned a new package ID (`com.eolnmsuk.choysee`). Installing ChoySee in place of Choicy keeps your saved tweak rules. The package listing now credits EolnMsuk and links to the ChoySee project.
- Added native **Roothide** support, including finding tweaks in Roothide’s own folders. The **Rootless**, **Roothide**, and **modern Rootful** packages require iOS 15 or later and have filenames that identify the jailbreak type.
- Added a separate **Legacy Rootful** download. It targets iOS 10 or later, up from the original Rootful build’s iOS 8 target, and requires iOS 12 or later on arm64e. The legacy build also fixes a tweak-loading issue on 32-bit devices.

#### Which package should I use?

Match the package to your jailbreak type, then check the iOS minimum.

| Jailbreak profile | Minimum iOS | Build source | `.deb` filename |
| --- | --- | --- | --- |
| Rootless | iOS 15.0 | GitHub Actions | `com.eolnmsuk.choysee_2.0.0_rootless.deb` |
| Native Roothide | iOS 15.0 | GitHub Actions | `com.eolnmsuk.choysee_2.0.0_roothide.deb` |
| Modern Rootful | iOS 15.0 | GitHub Actions | `com.eolnmsuk.choysee_2.0.0_rootful.deb` |
| Legacy Rootful | iOS 10.0 on `armv7` and `arm64`, iOS 12.0 on legacy `arm64e` | Local macOS build | `com.eolnmsuk.choysee_2.0.0_rootful_legacy_ios10.deb` |

All four packages require a tweak loader that provides `mobilesubstrate`, AltList 1.0.4 or later, and PreferenceLoader.

### Home Screen

- Added **ChoySee Settings** to the Home Screen shortcut menu so you can open an app’s tweak settings directly from its icon.
- Added **Tag Custom Apps**. A small grey dot appears at the bottom right of an app icon when the app has custom rules, has tweaks turned off, or overrides an active global rule. The dot also appears when an app extension has custom rules or tweaks turned off.
- The new settings shortcut and icon dots are on by default on iOS 15 and later and off by default on earlier versions. Both have switches in **App Options**.
- **Launch Without Tweaks** is now off by default. You can enable it or **Launch With Tweaks** in **App Options**.

### Tweak settings

- Apps with active rules appear alphabetically in a new **Configured** section at the top of **Applications**. Configured background services appear first in **Daemons**.
- App extensions, including VPN extensions, can move their app into **Configured**. An app with no active rules of its own can show its extension’s status next to its name.
- Tweaks disabled globally are hidden from individual **Allow** and **Deny** lists. Turn on **Overwrite Global Tweak Configuration** to see those tweaks and manage them there.
- Settings lists, status labels, and Home Screen dots refresh after rules are saved or reset. The app list and dots also refresh when apps or extensions are installed or removed.
- Missing or invalid saved rules fall back to defaults. On a fresh setup, saving rules for a running app closes it so the rules take effect the next time you open it.
- Updated existing translations and troubleshooting messages for the ChoySee name and added English text for the new options. **Tweak Troubleshooting** now recognizes and skips ChoySee’s own package.

### Updates, links, and donations

- Added **Updates** under **Settings → ChoySee → Other**. Tap it to compare your installed version with the latest stable release on GitHub. If a newer release is available, tap **View Release** to open its page.
- Replaced the old source code and Mastodon links with **GitHub** for the ChoySee project and **Reddit** for EolnMsuk’s profile. The Reddit link has its own icon. **Credits** now links to EolnMsuk and original Choicy developer opa334 alongside the existing contributors.
- Replaced the PayPal link with a **Donate** menu for Venmo and eight crypto wallets. Venmo opens in your default browser on supported versions of iOS. Each wallet shows its network and address. Tapping a wallet copies its full address and confirms the copy on screen and through VoiceOver.

### Release packaging

- The three modern packages use a newer build setup and can be built on demand through GitHub. Package checks verify that modern and legacy downloads contain the required files and match the intended jailbreak type. The project now bundles the source for two libraries used to build it.
- Added installation and upgrade instructions, along with screenshots of the older Settings layout.

### Full file list

#### Modified in place

- `.gitignore`
- `ChoicyPrefs/CHPApplicationListSubcontrollerController.m`
- `ChoicyPrefs/CHPCreditsListController.m`
- `ChoicyPrefs/CHPDaemonList.m`
- `ChoicyPrefs/CHPDaemonListController.m`
- `ChoicyPrefs/CHPListController.m`
- `ChoicyPrefs/CHPPackageInfo.m`
- `ChoicyPrefs/CHPPreferences.h`
- `ChoicyPrefs/CHPProcessConfigurationListController.h`
- `ChoicyPrefs/CHPProcessConfigurationListController.m`
- `ChoicyPrefs/CHPRootListController.m`
- `ChoicyPrefs/CHPTweakList.m`
- `ChoicyPrefs/CHPTweakTroubleshootListController.m`
- `ChoicyPrefs/entry.plist`
- `ChoicyPrefs/Makefile`
- `ChoicyPrefs/Resources/Credits.plist`
- `ChoicyPrefs/Resources/Info.plist`
- `ChoicyPrefs/Resources/Root.plist`
- `ChoicySB/ChoicySB.h`
- `ChoicySB/Makefile`
- `ChoicySB/SpringBoard.h`
- `ChoicySB/SpringBoard.x`
- `ChoicySB/Tweak.x`
- `control`
- `gen.c`
- `gen_asm.sh`
- `Makefile`
- `README.md`
- `release_build.sh`
- `Shared.h`
- `Shared.m`
- `Tweak.c`
- `Tweak.s`
- `update_localizations.sh`

#### Moved to `ChoySee.bundle`

These files were previously under `layout/Library/Application Support/Choicy.bundle/`.

**Moved and edited**

- `layout/Library/Application Support/ChoySee.bundle/ar.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/de.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/el.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/en.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/he.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/ru.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/zh_CN.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/zh_Hans.lproj/Localizable.strings`
- `layout/Library/Application Support/ChoySee.bundle/zh_TW.lproj/Localizable.strings`

**Moved**

- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon@2x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon@3x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Big@2x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Big@3x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Crossed@2x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Crossed@3x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Crossed_Big@2x.png`
- `layout/Library/Application Support/ChoySee.bundle/AppLaunchIcon_Crossed_Big@3x.png`

#### Added

**ChoySee files**

- `.github/scripts/verify-package.py`
- `.github/workflows/build.yml`
- `changelog.md`
- `ChoicyPrefs/ChoySeeDonationController.h`
- `ChoicyPrefs/ChoySeeDonationController.m`
- `ChoicyPrefs/ChoySeeSettingsPresentation.h`
- `ChoicyPrefs/ChoySeeUpdateChecker.h`
- `ChoicyPrefs/ChoySeeUpdateChecker.m`
- `ChoicyPrefs/Resources/Reddit@2x.png`
- `ChoicyPrefs/Resources/Reddit@3x.png`
- `ChoicyRoot.h`
- `control.legacy`
- `legacy_build.sh`
- `scripts/legacy-clang.sh`
- `scripts/package-legacy.py`
- `scripts/package_metadata.py`
