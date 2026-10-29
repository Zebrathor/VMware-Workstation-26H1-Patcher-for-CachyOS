#!/usr/bin/env bash
# Script for VMware Workstation 26H1 on CachyOS (and LLVM kernels)
# Author: Zebrathor
# Copyright (C) 2026 Zebrathor

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with SUDO." >&2
  exit 1
fi

KVER=$(uname -r)
BUILD_DIR=$(mktemp -d)
SOURCE_DIR="/usr/lib/vmware/modules/source"

trap 'rm -rf "$BUILD_DIR"' EXIT

echo "======================================================="
echo "  VMware 26H1 Patcher for LLVM Kernels (CachyOS)"
echo "  Detected Kernel: $KVER"
echo "======================================================="

if [ ! -f "$SOURCE_DIR/vmmon.tar" ] || [ ! -f "$SOURCE_DIR/vmnet.tar" ]; then
  echo -e "Error VMware source files not found. \nMake sure you have installed the VMware .bundle first." >&2
  exit 1
fi

echo "=> [1/6] Checking build dependencies (headers, make, clang, lld, pahole)..."
if [ ! -d "/usr/lib/modules/$KVER/build" ]; then
    PKG_PREFIX=$(echo "$KVER" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-//')
    HEADERS_PKG="linux-${PKG_PREFIX}-headers"
    pacman -S --needed --noconfirm "$HEADERS_PKG" > /dev/null 2>&1
fi
pacman -S --needed --noconfirm base-devel clang lld pahole > /dev/null 2>&1

echo "=> [2/6] Extracting official source code..."
cd "$BUILD_DIR"
tar -xf "$SOURCE_DIR/vmmon.tar"
tar -xf "$SOURCE_DIR/vmnet.tar"

echo "=> [3/6] Compiling Virtual Machine Monitor (vmmon)..."
cd vmmon-only
make clean > /dev/null 2>&1
make -j"$(nproc)" LLVM=1 > /dev/null
if [ ! -f "vmmon.ko" ]; then
    echo "Error vmmon compilation failed." >&2
    exit 1
fi
cd ..

echo "=> [4/6] Compiling Virtual Ethernet (vmnet)..."
cd vmnet-only
make clean > /dev/null 2>&1
make -j"$(nproc)" LLVM=1 > /dev/null
if [ ! -f "vmnet.ko" ]; then
    echo "Error vmnet compilation failed." >&2
    exit 1
fi
cd ..

echo "=> [5/6] Injecting new modules into the kernel..."
mkdir -p "/lib/modules/$KVER/misc"
cp vmmon-only/vmmon.ko "/lib/modules/$KVER/misc/"
cp vmnet-only/vmnet.ko "/lib/modules/$KVER/misc/"
depmod -a

echo "=> [6/6] Creating persistent startup service (systemd)..."
cat <<EOF > /etc/systemd/system/vmware-manual.service
[Unit]
Description=VMware Host Modules & Networks (Manual)
After=network.target

[Service]
Type=oneshot
ExecStartPre=/usr/sbin/modprobe vmmon
ExecStartPre=/usr/sbin/modprobe vmnet
ExecStart=/usr/bin/vmware-networks --start
ExecStartPost=-/usr/bin/vmware-usbarbitrator
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vmware-manual.service > /dev/null 2>&1
systemctl restart vmware-manual.service > /dev/null 2>&1

echo "======================================================="
echo "     Success! VMware Workstation is ready to use."
echo "     The modules will load automatically on boot."
echo "======================================================="
