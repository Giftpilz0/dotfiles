#!/bin/bash

# --- DCONF SYSTEM-WIDE UPDATE ---
echo "Running system-wide dconf update..."
sudo dconf update

sleep 3

# --- DCONF RESET ---
echo "Resetting all dconf keys for user: $(whoami)"
dbus-run-session -- dconf reset -f /
