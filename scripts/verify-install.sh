#!/usr/bin/env bash
set -Eeuo pipefail

echo "Architecture:"
uname -m

echo
echo "Box64:"
if command -v box64 >/dev/null 2>&1; then
    box64 --version || true
else
    echo "box64 not found"
fi

echo
echo "synosnap DKMS:"
dkms status synosnap 2>/dev/null || true

echo
echo "synosnap module:"
lsmod | grep synosnap || true
ls -l /dev/synosnap* 2>/dev/null || true

echo
echo "ABB service:"
systemctl status abb-box64.service --no-pager || true
systemctl is-enabled abb-box64.service || true

echo
echo "ABB CLI:"
if command -v abb-cli >/dev/null 2>&1; then
    abb-cli -s || true
else
    echo "abb-cli wrapper not found"
fi

echo
echo "Note:"
echo "  For RPM VM install validation, use scripts/verify-rpm-vm.sh."
