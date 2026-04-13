# meta-agl-app-store

Yocto/BitBake meta layer for the **AGL PENS App Store** — a Flutter-based embedded application store for Automotive Grade Linux (AGL) with Flatpak support.

Based on the [meta-flatpak AGL integration guide](https://github.com/flatpak/meta-flatpak/blob/AGL/AGL.md).

## Overview

This layer provides:

1. **Flutter App Store recipe** (`agl-app-store.bb`) — builds the [AGL App Store](https://github.com/mukhayyar/agl-app-store) Flutter embedded client
2. **Flatpak packagegroup** (`packagegroup-flatpak.bb`) — pulls in flatpak, ostree, gnupg, ca-certificates
3. **Pre-configured repositories** (`flatpak-predefined-repos.bb`) — registers **PENSHub** and **Flathub** on first boot with GPG verification
4. **Platform integration** (`packagegroup-agl-demo-platform-flutter.bbappend`) — adds the app to the AGL IVI homescreen
5. **Distro include** (`agl-app-store-flatpak.inc`) — configures distro features and rootfs space for Flatpak

## Directory Structure

```
agl_meta-agl-app-store/
├── conf/
│   ├── layer.conf
│   └── distro/include/
│       └── agl-app-store-flatpak.inc       # Include in local.conf for Flatpak support
├── recipes-agl-app-store/
│   └── agl-app-store/
│       ├── agl-app-store.bb                # Flutter app store recipe
│       └── files/
│           └── agl-app-flutter@agl-app-store.service  # Systemd service for IVI
├── recipes-core/
│   └── packagegroups/
│       └── packagegroup-flatpak.bb         # Flatpak + OSTree + deps
├── recipes-flatpak/
│   └── flatpak-predefined-repos/
│       ├── flatpak-predefined-repos.bb     # First-boot repo setup service
│       └── files/
│           └── setup-flatpak-repos.sh      # Registers PENSHub + Flathub with GPG
└── recipes-platform/
    └── packagegroups/
        └── packagegroup-agl-demo-platform-flutter.bbappend  # Adds app to IVI
```

## Layer Dependencies

| Layer | Purpose |
|---|---|
| `meta-flutter` | Flutter embedder + `flutter-app` class |
| `meta-app-framework` | AGL app framework (`agl-app` class) |
| `meta-oe` | Provides base `flatpak` and `ostree` recipes |

> **Note:** This layer does **not** bundle its own `flatpak_git.bb` or `ostree_git.bb`.
> It relies on the base Flatpak recipe from `meta-oe` (or the official `meta-flatpak`
> layer if you use it). No bbappend files for flatpak are needed.

## Setup

### 1. Gather AGL sources and set up build environment

```bash
source agl-init-build-env
```

### 2. Add this layer and required dependencies

```bash
# These may already be included in your AGL config
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-gnome
bitbake-layers add-layer ../meta-openembedded/meta-filesystems
bitbake-layers add-layer ../meta-openembedded/meta-networking

# Add our layer
bitbake-layers add-layer ../meta-agl-app-store
```

### 3. Configure `local.conf`

Add the following to your `local.conf`:

```bash
# Option A: Use the provided distro include (recommended)
include conf/distro/include/agl-app-store-flatpak.inc

# Option B: Manual configuration
# IMAGE_INSTALL:append = " flatpak agl-app-store"
# IMAGE_ROOTFS_EXTRA_SPACE:append = " + 4000000"
# DISTRO_FEATURES:append = " wayland seccomp"
```

### 4. Build

```bash
# Build just the app store recipe
bitbake agl-app-store

# Build the full AGL IVI image
bitbake agl-ivi-demo-flutter
```

### 5. Run with QEMU

```bash
runqemu kvm serialstdio slirp publicvnc
```

## Flatpak Repositories

On first boot, the device configures two Flatpak remotes:

| Remote | URL | GPG |
|---|---|---|
| **penshub** | `https://repo.agl-store.cyou` | Key fetched from `/public.gpg` |
| **flathub** | `https://dl.flathub.org/repo` | Bundled with Flatpak |

The `org.gnome.Platform//46` shared runtime is also installed from Flathub if network is available.

## Security & GPG Verification

The PENSHub remote is added **with GPG verification enabled**. On first boot:
1. The setup script fetches the GPG public key from `https://repo.agl-store.cyou/public.gpg`
2. Imports it via `flatpak remote-add --gpg-import=<keyring>`
3. If the key fetch fails (no network), setup is deferred to the next boot

No `--no-gpg-verify` is used.

## Testing Flatpak on the image

After booting, verify Flatpak works via SSH or serial:

```bash
# Check remotes are configured
flatpak remote-list --system

# List available apps from PENSHub
flatpak remote-ls --system penshub

# Install an app from PENSHub
flatpak install --system penshub com.pens.Calculator

# Run it
flatpak run com.pens.Calculator
```

## Production Notes

- Pin `SRCREV` in `agl-app-store.bb` to a specific commit hash for reproducible builds
- Adjust `IMAGE_ROOTFS_EXTRA_SPACE` based on target storage (4GB default)
- Wayland apps from Flathub work out of the box with AGL compositor
- Qt apps from Flathub need: `flatpak run --env=QT_QPA_PLATFORM=wayland <app-id>`

## Compatible AGL Version

- **Scarthgap** (AGL latest)

## Author

Muhammad Tsaqif Mukhayyar — Politeknik Elektronika Negeri Surabaya (PENS)
