"""Print the hosts of an OpenSSH client config as JSON for the DMS SSH launcher.

Comments inside a Host block add launcher data:
    # fuzzel-users: root, admin    extra users offered in the user picker
    # waypipe: firefox             app started through waypipe (repeatable)
    # waypipe-args: -c zstd=15     waypipe options for this host's apps
"""

import glob
import json
import os
import re
import sys

SSH_DIR = os.path.expanduser("~/.ssh")
OPTION = re.compile(r"(\w+)\s*(?:=\s*|\s+)(.*)")


def unquote(value):
    return value[1:-1] if len(value) > 1 and value[0] == value[-1] == '"' else value


def host_entry(hosts, name):
    if name not in hosts:
        hosts[name] = {
            "host": name,
            "user": None,
            "extraUsers": [],
            "waypipe": [],
            "waypipeArgs": "",
        }
    return hosts[name]


def apply_comment(text, block):
    key, sep, value = text.partition(":")
    if not sep:
        return
    key, value = key.strip().lower(), value.strip()
    for entry in block:
        if key == "fuzzel-users":
            for user in value.split(","):
                user = user.strip()
                if user and user not in entry["extraUsers"]:
                    entry["extraUsers"].append(user)
        elif key == "waypipe" and value:
            entry["waypipe"].append(value)
        elif key == "waypipe-args":
            entry["waypipeArgs"] = value


def parse(path, hosts, seen):
    path = os.path.realpath(os.path.expanduser(path))
    if path in seen:
        return
    seen.add(path)
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        print(f"{path}: {e}", file=sys.stderr)
        return

    block = []
    for raw in lines:
        line = raw.strip()
        if line.startswith("#"):
            apply_comment(line[1:], block)
            continue
        match = OPTION.fullmatch(line)
        if not match:
            continue
        key, value = match[1].lower(), match[2].strip()

        if key == "include":
            for pattern in value.split():
                pattern = os.path.expanduser(unquote(pattern))
                if not os.path.isabs(pattern):
                    pattern = os.path.join(SSH_DIR, pattern)
                for included in sorted(glob.glob(pattern)):
                    parse(included, hosts, seen)
        elif key == "host":
            names = [unquote(n) for n in value.split()]
            block = [
                host_entry(hosts, n) for n in names if not any(c in n for c in "*?!")
            ]
        elif key == "match":
            block = []
        elif key == "user":
            for entry in block:
                if entry["user"] is None:
                    entry["user"] = unquote(value)


def main():
    hosts = {}
    parse(sys.argv[1] if len(sys.argv) > 1 else "~/.ssh/config", hosts, set())
    print(json.dumps(list(hosts.values())))


if __name__ == "__main__":
    main()
