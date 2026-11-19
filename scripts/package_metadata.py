"""Release identity and payload shared by the modern and legacy package verifiers."""

from pathlib import Path
import plistlib
import re


PROJECT = Path(__file__).resolve().parents[1]
IDENTITY = {
    "Package": "com.eolnmsuk.choysee",
    "Name": "ChoySee",
    "Author": "EolnMsuk",
    "Maintainer": "EolnMsuk",
    "Conflicts": "com.opa334.choicy",
    "Replaces": "com.opa334.choicy",
    "Homepage": "https://github.com/EolnMsuk/ChoySee/",
}
RUNTIME_DEPENDENCIES = {"mobilesubstrate", "com.opa334.altlist (>= 1.0.4)", "preferenceloader"}
DYLIBS = "Library/MobileSubstrate/DynamicLibraries"
PREFS = "Library/PreferenceBundles/ChoySeePrefs.bundle"
PREFS_INFO = f"{PREFS}/Info.plist"
IMAGES = (f"{DYLIBS}/   Choicy.dylib", f"{DYLIBS}/ChoicySB.dylib", f"{PREFS}/ChoySeePrefs")


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def dependency_entries(value):
    # Packaging tools can rewrite whitespace around version constraints.
    versioned = r"^([^\s()]+)\s*\(\s*(<<|<=|=|>=|>>)\s*([^\s()]+)\s*\)$"
    return [re.sub(versioned, r"\1 (\2 \3)", entry.strip()) for entry in value.split(",")]


def control_fields(control):
    fields = {}
    for line in control.splitlines():
        key, separator, value = line.partition(":")
        require(separator and key not in fields, f"Invalid control field: {line!r}")
        if key == "Depends":
            value = ", ".join(dependency_entries(value))
        fields[key] = value.strip()
    return fields


def verify_metadata(fields, architecture, version):
    expected = {**IDENTITY, "Version": version, "Architecture": architecture}
    for key, value in expected.items():
        require(fields.get(key) == value, f"Unexpected {key}: {fields.get(key)!r}. Expected {value!r}.")


def verify_dependencies(fields, minimum_ios, *, allow_additional=False):
    dependencies = dependency_entries(fields.get("Depends", ""))
    expected = RUNTIME_DEPENDENCIES | {f"firmware (>= {minimum_ios})"}
    require(expected.issubset(dependencies) and (allow_additional or len(dependencies) == len(expected)),
            f"Unexpected iOS {minimum_ios} dependencies: {dependencies!r}")


def verify_bundle_metadata(data, version):
    info = plistlib.loads(data)
    expected = {
        "CFBundleExecutable": "ChoySeePrefs",
        "CFBundleIdentifier": "com.eolnmsuk.choyseeprefs",
        "CFBundleShortVersionString": version,
        "CFBundleVersion": version,
        "NSPrincipalClass": "CHPRootListController",
    }
    for key, value in expected.items():
        require(info.get(key) == value, f"Unexpected Settings bundle {key}: {info.get(key)!r}. Expected {value!r}.")


def modern_metadata():
    fields = control_fields((PROJECT / "control").read_text(encoding="utf-8"))
    version = fields.get("Version", "")
    require(re.fullmatch(r"[0-9][A-Za-z0-9.+~\-]*", version), f"Invalid release version in control: {version!r}")
    verify_metadata(fields, "iphoneos-arm", version)
    verify_dependencies(fields, "15.0")
    verify_bundle_metadata((PROJECT / "ChoicyPrefs/Resources/Info.plist").read_bytes(), version)
    return fields


def required_payload():
    layout = PROJECT / "layout"
    support = layout / "Library/Application Support/ChoySee.bundle"
    require(any(support.glob("*.lproj/Localizable.strings")), "Missing ChoySee support localizations")
    # Match Theos's default staging exclusions for filesystem metadata.
    ignored = {".DS_Store", ".git", ".svn", "_MTN"}
    resources = []
    for path in (layout / "Library").rglob("*"):
        relative = path.relative_to(layout)
        if path.is_file() and not any(part in ignored or part.startswith("._") for part in relative.parts):
            resources.append(relative.as_posix())
    return (
        *IMAGES,
        f"{DYLIBS}/   Choicy.plist",
        f"{DYLIBS}/ChoicySB.plist",
        PREFS_INFO,
        f"{PREFS}/Root.plist",
        f"{PREFS}/Credits.plist",
        f"{PREFS}/Reddit@2x.png",
        f"{PREFS}/Reddit@3x.png",
        f"{PREFS}/GitHub@2x.png",
        f"{PREFS}/GitHub@3x.png",
        f"{PREFS}/Donate@2x.png",
        f"{PREFS}/Donate@3x.png",
        f"{PREFS}/Credits@2x.png",
        f"{PREFS}/Credits@3x.png",
        "Library/PreferenceLoader/Preferences/ChoySeePrefs.plist",
        *sorted(resources),
    )


def release_filename(metadata, profile):
    return f"{metadata['Package']}_{metadata['Version']}_{profile}.deb"
