# VMware Workstation 26H1 Patcher for CachyOS (LLVM Kernels)

Automated bash script to fix the `Failed to get gcc information` error when installing VMware Workstation 26H1 (`.bundle`) on CachyOS and other Arch-based distributions using LLVM/Clang compiled kernels.

## Features
* Automatically detects your CachyOS kernel variant and installs the matching headers.
* Compiles `vmmon` and `vmnet` natively using the `LLVM=1` flag and multi-core acceleration.
* Creates and enables a persistent `systemd` service so VMware modules and networking start automatically on boot.

## Prerequisites
* A system running **CachyOS** (or Arch Linux with an LLVM-built kernel).
* The official **VMware Workstation 26H1 `.bundle`** already installed on your system:
  ```bash
  sudo ./VMware-Workstation-Full-*.bundle
## Usage
1. Install the official VMware Workstation `.bundle` installer first.
2. Clone this repository or download the script:
   ```bash
   chmod +x vmware-cachyos-fix.sh
   sudo ./vmware-cachyos-fix.sh