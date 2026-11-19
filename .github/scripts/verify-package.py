#!/usr/bin/env python3
"""Verify one fresh modern package before assigning its downloadable filename."""

import argparse
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from package_metadata import (DYLIBS, IDENTITY, IMAGES, PREFS_INFO, PROJECT, modern_metadata, release_filename,
                              required_payload, verify_bundle_metadata, verify_dependencies, verify_metadata)


ARCHITECTURES = {"rootless": "iphoneos-arm64", "roothide": "iphoneos-arm64e", "rootful": "iphoneos-arm"}


def output(*command):
    return subprocess.check_output(command, text=True).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--label", required=True, type=str.lower, choices=ARCHITECTURES)
    parser.add_argument("--architecture")
    parser.add_argument("--package-dir", type=Path, default=PROJECT / "packages")
    args = parser.parse_args()
    profile = args.label
    architecture = ARCHITECTURES[profile]
    if args.architecture is not None and args.architecture != architecture:
        raise SystemExit("Label and expected architecture disagree")
    packages = list(args.package_dir.glob("*.deb"))
    if len(packages) != 1:
        raise SystemExit(f"Expected exactly one fresh .deb; found {len(packages)}")
    package = packages[0]
    fields = (*IDENTITY, "Version", "Architecture", "Depends")
    metadata = {key: output("dpkg-deb", "-f", str(package), key) for key in fields}
    verify_metadata(metadata, architecture, modern_metadata()["Version"])
    verify_dependencies(metadata, "15.0", allow_additional=True)

    listing = output("dpkg-deb", "-c", str(package))
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        review = PROJECT / ".ci"
        review.mkdir(exist_ok=True)
        (review / f"payload-{profile}.txt").write_text(listing + "\n", encoding="utf-8")

    payload = subprocess.check_output(["dpkg-deb", "--fsys-tarfile", str(package)])
    prefix = "var/jb/" if profile == "rootless" else ""
    with tarfile.open(fileobj=io.BytesIO(payload), mode="r:") as archive, tempfile.TemporaryDirectory() as scratch:
        members = {member.name.removeprefix("./").rstrip("/"): member for member in archive.getmembers()}
        for relative in required_payload():
            name = prefix + relative
            member = members.get(name)
            if member is None or not member.isfile() or not member.size:
                raise SystemExit(f"Missing or empty payload file: /{name}")
            # dpkg-deb -c must also show the exact filename, including its spaces.
            if name not in listing:
                raise SystemExit(f"Payload absent from dpkg-deb -c listing: {name}")
            alternate = relative if prefix else "var/jb/" + relative
            if alternate in members:
                raise SystemExit(f"Unexpected payload for another package scheme: /{alternate}")
        for suffix in ("dylib", "plist"):
            if prefix + f"{DYLIBS}/Choicy.{suffix}" in members:
                raise SystemExit("Choicy staged without the three-space load-order prefix")
        verify_bundle_metadata(archive.extractfile(members[prefix + PREFS_INFO]).read(), metadata["Version"])
        for relative in IMAGES:
            image = Path(scratch) / Path(relative).name.strip()
            image.write_bytes(archive.extractfile(members[prefix + relative]).read())
            slices = set(output("lipo", "-archs", str(image)).split())
            if slices != {"arm64", "arm64e"}:
                raise SystemExit(f"Unexpected Mach-O architectures in {relative}: {sorted(slices)!r}")
            if profile == "roothide":
                # Native RootHide stages at /Library and links via .jbroot.
                dependencies = output("otool", "-L", str(image))
                if ".jbroot/" not in dependencies or "libroothide.dylib" not in dependencies:
                    raise SystemExit(f"Missing native RootHide linkage in {relative}:\n{dependencies}")

    artifacts = PROJECT / "artifacts"
    artifacts.mkdir(exist_ok=True)
    destination = artifacts / release_filename(metadata, profile)
    with tempfile.TemporaryDirectory(prefix=".verified-", dir=artifacts) as scratch:
        verified = Path(scratch) / destination.name
        shutil.copy2(package, verified)
        os.replace(verified, destination)
    if github_output:
        with open(github_output, "a", encoding="utf-8") as stream:
            stream.write(f"path={destination.relative_to(PROJECT).as_posix()}\nstem={destination.stem}\n")
    print(f"Verified {metadata['Package']} {metadata['Version']} {metadata['Architecture']}: {destination}")


if __name__ == "__main__":
    main()
