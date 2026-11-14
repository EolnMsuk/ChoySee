# ChoySee

A forked (enhanced) version of [Choicy](https://github.com/opa334/Choicy), an advanced tweak configurator!

## Features

- Disable tweak injection individually for every process
- Configure each tweak dylib individually for every process
- Disable tweaks globally (with the ability to set exceptions for individual processes)
- Option for an application shortcut to launch the application with or without tweaks once
- **NEW** - A Choicy Settings shortcut opens the selected app's tweak configuration.
- **NEW** - Tag Custom Apps adds a grey dot to apps with custom rules, disabled injection, an active global override, or an App Plugin with custom rules or disabled injection.
- **NEW** - Auto sorts the application and daemon lists to show configured at the top.

Tag Custom Apps and the Choicy Settings option default to on on iOS 15 and later, and off on earlier versions. Saved choices and the existing preference plist remain compatible when updating to b4; no reset is needed.

## Install Choicy on iOS 15+

1. Download the deb file matching your jailbreak environment from the [latest release](https://github.com/EolnMsuk/ChoySee/releases/latest) 
2. Open it with Sileo or Zebra and install 

| Environment | Firmware dependency | Filename |
| --- | --- | --- |
| GitHub Rootless | `>= 15.0` | `Choicy_1.5.5~b4_Rootless.deb` |
| GitHub native Roothide | `>= 15.0` | `Choicy_1.5.5~b4_Roothide.deb` |
| GitHub Rootful | `>= 15.0` | `Choicy_1.5.5~b4_Rootful.deb` |
| Local Legacy Rootful | `>= 10.0` | `Choicy_1.5.5~b4_Rootful_Legacy_iOS10.deb` |

---

### Legacy Rootful on a prepared macOS host

Select this profile explicitly when targeting older Rootful jailbreaks. The shared sources target iOS 10.0 on `armv7` and `arm64`, and iOS 12.0 on old-ABI `arm64e`. From the project root, with `THEOS_PACKAGE_SCHEME` unset or empty, run the following with local paths to the prepared tools.

```sh
THEOS=/absolute/path/to/prepared/theos \
LEGACY_PREFIX=/absolute/path/to/Xcode11.7.xctoolchain/usr/bin/ \
LEGACY_SDKROOT=/absolute/path/to/prepared/theos/sdks/iPhoneOS13.7.sdk \
GEN_CLANG=/absolute/path/to/musttail-capable/clang \
sh ./legacy_build.sh
```

## Credit

- EolnMsuk: [ChoySee](https://github.com/EolnMsuk/ChoySee) | [Donate](https://venmo.com/u/RustOnRails/)
- oppa334: [Choicy](https://github.com/opa334/Choicy) | [Donate](opa334.github.io/donate.html)
