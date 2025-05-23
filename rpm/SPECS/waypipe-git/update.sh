#!/usr/bin/bash
set -euxo pipefail

ec=0

SPEC=waypipe-git.spec

oldTag="$(rpmspec -q --qf "%{version}\n" $SPEC | head -1 | sed 's/\^.*//')"
newTag="$(curl -s "https://gitlab.freedesktop.org/api/v4/projects/mstoeckl%2Fwaypipe/repository/tags" | jq -r '.[0].name' | sed 's/^v//')"

oldCommit="$(sed -n 's/.*\bcommit0\b \(.*\)/\1/p' $SPEC)"
newCommit="$(curl -s "https://gitlab.freedesktop.org/api/v4/projects/mstoeckl%2Fwaypipe/repository/commits" | jq -r '.[0].id')"


sed -i "s/$oldCommit/$newCommit/" $SPEC

rpmdev-vercmp "$oldTag" "$newTag" || ec=$?
case $ec in
    0) ;;
    12)
        perl -pe 's/(?<=bumpver\s)(\d+)/0/' -i $SPEC
        sed -i "/^Version:/s/$oldTag/$newTag/" $SPEC ;;
    *) exit 1
esac
