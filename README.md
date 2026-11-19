# ChoySee

ChoySee is EolnMsuk’s fork of opa334’s Choicy for configuring tweak injection on jailbroken iOS.

---

<img width="4773" height="2589" alt="Historical screenshots of the Choicy Settings interface" src="https://github.com/user-attachments/assets/e191b5bd-8d7b-4108-bde1-971d11b46af4" />

## Features

- Disable tweak injection individually for every process
- Configure each tweak dylib individually for every process
- Disable tweaks globally (with the ability to set exceptions for individual processes)
- Option for an application shortcut to launch the application with or without tweaks once
- Open an app’s injection settings from its **ChoySee Settings** Home Screen shortcut.
- Mark apps with custom rules or disabled injection with a grey dot on their icons.
- Show configured apps and daemons first in their respective lists.

## Install ChoySee

Download the file for your jailbreak environment from the [latest ChoySee release](https://github.com/EolnMsuk/ChoySee/releases/latest).

| Profile | Firmware dependency | Filename |
| --- | --- | --- |
| Rootless | iOS 15.0+ | `com.eolnmsuk.choysee_2.0.1_rootless.deb` |
| Native Roothide | iOS 15.0+ | `com.eolnmsuk.choysee_2.0.1_roothide.deb` |
| Modern Rootful | iOS 15.0+ | `com.eolnmsuk.choysee_2.0.1_rootful.deb` |
| Legacy Rootful | iOS 10.0+ | `com.eolnmsuk.choysee_2.0.1_rootful_legacy_ios10.deb` |

## Build profiles

On a prepared macOS host, `sh ./release_build.sh` verifies and copies the three modern downloads to `artifacts/`. The legacy build uses a separate entry point and writes to `artifacts/legacy/`.

### Legacy Rootful on a prepared macOS host

Select this profile explicitly when targeting older Rootful jailbreaks. The shared sources target iOS 10.0 on `armv7` and `arm64`, and iOS 12.0 on old-ABI `arm64e`. From the project root, with `THEOS_PACKAGE_SCHEME` unset or empty, run the following with local paths to the prepared tools.

```sh
THEOS=/absolute/path/to/prepared/theos \
LEGACY_PREFIX=/absolute/path/to/Xcode11.7.xctoolchain/usr/bin/ \
LEGACY_SDKROOT=/absolute/path/to/prepared/theos/sdks/iPhoneOS13.7.sdk \
GEN_CLANG=/absolute/path/to/musttail-capable/clang \
sh ./legacy_build.sh
```

## Credits

- EolnMsuk ChoySee. [EolnMsuk on GitHub](https://github.com/EolnMsuk)
- opa334 Choicy. [Original Choicy repository](https://github.com/opa334/Choicy)
