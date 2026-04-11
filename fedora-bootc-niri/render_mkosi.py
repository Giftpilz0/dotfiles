#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "ansible" / "vars" / "package-manifest.json"
MKOSI_CONF_PATH = ROOT / "fedora-bootc-niri" / "mkosi.conf.d" / "20-content.conf"
FLATPAK_PREINSTALL_PATH = (
    ROOT
    / "fedora-bootc-niri"
    / "mkosi.extra"
    / "usr"
    / "share"
    / "flatpak"
    / "preinstall.d"
    / "fedora-bootc-niri.preinstall"
)


def dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            ordered.append(item)
    return ordered


def indent(items: list[str]) -> str:
    return "".join(f"    {item}\n" for item in items)


def render_content_conf(manifest: dict[str, object]) -> str:
    packages = dedupe(
        manifest["package_groups"]
        + manifest["common_packages"]
        + manifest["bootc_packages"]
        + manifest["bootc_image_packages"]
    )
    x86_64_packages = dedupe(manifest["bootc_x86_64_packages"])
    remove_files = dedupe(manifest["remove_files"])
    remove_packages = dedupe(manifest["remove_packages"])

    lines = [
        "# Generated from ansible/vars/package-manifest.json.",
        "# Run `python3 fedora-bootc-niri/render_mkosi.py` after changing the manifest.",
        "",
        "[Match]",
        "Distribution=fedora",
        "",
        "[Content]",
        "RemoveFiles=",
        indent(remove_files).rstrip(),
        "",
        "RemovePackages=",
        indent(remove_packages).rstrip(),
        "",
        "Packages=",
        indent(packages).rstrip(),
        "",
        "[Match]",
        "Distribution=fedora",
        "Architecture=x86-64",
        "",
        "[Content]",
        "Packages=",
        indent(x86_64_packages).rstrip(),
        "",
    ]
    return "\n".join(lines)


def render_flatpak_preinstall(manifest: dict[str, object]) -> str:
    sections: list[str] = []
    for package in manifest["flatpak_packages"]:
        sections.extend(
            [
                f"[Flatpak Preinstall {package['name']}]",
                f"Branch={package.get('branch', 'stable')}",
                f"IsRuntime={'true' if package.get('is_runtime', False) else 'false'}",
                "",
            ]
        )
    return "\n".join(sections).rstrip() + "\n"


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text())
    MKOSI_CONF_PATH.write_text(render_content_conf(manifest))
    FLATPAK_PREINSTALL_PATH.write_text(render_flatpak_preinstall(manifest))


if __name__ == "__main__":
    main()
