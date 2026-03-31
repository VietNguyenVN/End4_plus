#!/usr/bin/env bash

echo "==> Arch Linux Service Status"

archstatus -l blackarch

echo
read -n 1 -s -r -p "==> Press any key to exit..."
