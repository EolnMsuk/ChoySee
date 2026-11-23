# 2.0.6

- Updated depiction.json / Sileo description of ChoySee.

# 2.0.5

- Refreshed banner image on the ChoySee package page in Sileo.

# 2.0.4

ChoySee is a continuation of Choicy 1.5.4 with support for modern jailbreaks, new Home Screen shortcuts, and an updated Settings layout. Installing ChoySee over Choicy automatically keeps all of your existing app and tweak settings.

### Compatibility & Installation

* **Modern Jailbreaks (iOS 15+):** Added native **Roothide** support alongside **Rootless** and **Modern Rootful** builds.
* **Older Devices (iOS 10–14):** Added a **Legacy Rootful** build (requires iOS 10+ on `armv7`/`arm64`, or iOS 12+ on `arm64e`), which also fixes tweak-loading issues on 32-bit devices.
* **Requirements:** Requires a tweak loader (`mobilesubstrate`), AltList 1.0.4 or later, and PreferenceLoader.
* **Sileo Listing:** Added an official Sileo package page featuring a header banner, swipeable screenshots, and full release notes.

### Home Screen Features

* **Quick Settings Shortcut:** Press and hold any app icon to open **ChoySee Settings** directly for that app (enabled by default on iOS 15+; toggleable in **App Options**).
* **Custom App Dots:** Added **Tag Custom Apps**, which places a small grey dot on the bottom-right corner of an app icon whenever that app or its extensions have custom rules or disabled tweaks (enabled by default on iOS 15+; toggleable in **App Options**).
* **Launch Options:** **Launch Without Tweaks** is now off by default, and can be enabled alongside **Launch With Tweaks** inside **App Options**.

### Tweak Settings & Organization

* **Configured Sections:** Apps and background daemons with active rules now appear in a **Configured** section at the top of their respective lists. Apps will also move to **Configured** if one of their extensions (such as a VPN extension) has custom rules.
* **Cleaner Tweak Lists:** Tweaks that are disabled globally are now hidden from individual app **Allow** and **Deny** lists unless you enable **Overwrite Global Tweak Configuration**.
* **Automatic Refreshing:** App lists, status labels, and Home Screen dots update automatically whenever you change rules, reset settings, or install/remove apps. Saving rules on a fresh setup will automatically close the target app so changes apply on the next launch.
* **Better Troubleshooting:** **Tweak Troubleshooting** now safely ignores ChoySee itself, and missing or corrupted rule files automatically fall back to safe defaults.

### Settings Layout, Updates & Links

* **In-App Update Checker:** Added an **Updates** button under **Settings → ChoySee → Other** to check for newer releases on GitHub.
* **Refreshed Menu & Footer:** Aligned icons and labels in the **Other** section, updated the **Donate** menu (supporting Venmo and one-tap copy for eight crypto wallets), and added a footer displaying your installed ChoySee version, iOS version, and jailbreak type.
* **Updated Links & Credits:** Added links to the ChoySee GitHub repository, EolnMsuk’s Reddit profile, and credits for both EolnMsuk and original Choicy developer opa334.