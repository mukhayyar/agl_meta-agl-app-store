# meta-agl-app-store

Yocto/BitBake meta layer for the **AGL PENS App Store** — a Flutter-based embedded application store for Automotive Grade Linux (AGL) with integrated Flatpak support.

## Overview

This layer provides everything needed to build and deploy the AGL App Store into an AGL Yocto image:

1. **Flutter App Store recipe** (`agl-app-store.bb`) — builds the [AGL App Store](https://github.com/mukhayyar/agl-app-store) Flutter embedded client
2. **Flatpak runtime support** (`packagegroup-flatpak.bb`) — pulls in Flatpak, OSTree, GPG, and CA certificates
3. **Flatpak bbappend** — tunes Flatpak build flags for AGL embedded (disables systemd-helper, seccomp, SELinux)
4. **Pre-configured repositories** (`flatpak-predefined-repos.bb`) — registers **PENSHub** and **Flathub** as system remotes on first boot

## Directory Structure

```
agl_meta-agl-app-store/
├── README.md
├── conf/
│   └── layer.conf                          # Layer configuration + Flatpak variables
├── classes/                                # (reserved for future bbclasses)
├── recipes-agl-app-store/
│   └── agl-app-store/
│       └── agl-app-store.bb               # Flutter app store recipe
├── recipes-core/
│   └── packagegroups/
│       └── packagegroup-flatpak.bb        # Flatpak + OSTree + deps
└── recipes-flatpak/
    ├── flatpak/
    │   ├── flatpak_%.bbappend             # Generic Flatpak tweaks
    │   └── flatpak_1.14.%.bbappend        # Version-specific AGL tweaks
    ├── flatpak-predefined-repos/
    │   ├── flatpak-predefined-repos.bb    # First-boot repo setup service
    │   └── files/
    │       └── setup-flatpak-repos.sh     # Registers PENSHub + Flathub
    └── ostree/                             # (bbappend if needed)
```

## Layer Dependencies

| Layer | Purpose | Repository |
|---|---|---|
| `meta-flutter` | Flutter embedder + `flutter-app` class | [meta-flutter](https://github.com/pomerium/meta-flutter) |
| `meta-app-framework` | AGL app framework (`agl-app` class) | Part of AGL layers |
| `meta-oe` | Provides base `flatpak` and `ostree` recipes | [meta-openembedded](https://github.com/openembedded/meta-openembedded) |

> **Note:** This layer does **not** bundle its own `flatpak_git.bb` or `ostree_git.bb` recipes.
> It relies on the base recipes from `meta-oe` (or the official `meta-flatpak` if available)
> and applies bbappend files to tune them for AGL.

## Setup

### 1. Add this layer to `bblayers.conf`

```bash
BBLAYERS += "/path/to/agl_meta-agl-app-store"
```

### 2. Add to your image (e.g., `local.conf`)

```bash
# Include the App Store + full Flatpak runtime
IMAGE_INSTALL:append = " agl-app-store"
```

This automatically pulls in:
- The Flutter app store client
- `packagegroup-flatpak` (flatpak, ostree, gnupg, ca-certificates, glib-networking)
- `flatpak-predefined-repos` (first-boot systemd service that adds PENSHub + Flathub)

### 3. Build

```bash
bitbake agl-app-store
```

### 4. (Optional) Full image build

```bash
bitbake agl-image-flutter
```

## Flatpak Repositories

On first boot, the device automatically configures two Flatpak remotes:

| Remote | URL | Description |
|---|---|---|
| **penshub** | `https://repo.agl-store.cyou` | PENS private app repository (130 GTK4 apps) |
| **flathub** | `https://dl.flathub.org/repo` | Public community Flatpak repository |

The `org.gnome.Platform//46` shared runtime is also installed from Flathub if network is available.

## Configuration Variables

Set these in `local.conf` to override defaults:

```bash
# Flatpak system installation directory
FLATPAK_SYSTEM_DIR = "/var/lib/flatpak"

# GPG signing identity for PENSHub
FLATPAK_GPGDIR = "${TOPDIR}/gpg"
FLATPAK_GPGID  = "pens-agl-store-signing@key"

# Repository URLs
FLATPAK_PENSHUB_URL = "https://repo.agl-store.cyou"
FLATPAK_FLATHUB_URL = "https://dl.flathub.org/repo"
```

## Production Notes

- Pin `SRCREV` in `agl-app-store.bb` to a specific commit hash for reproducible builds
- Replace `--no-gpg-verify` in `setup-flatpak-repos.sh` with your GPG public key for PENSHub
- The Flatpak bbappend disables `seccomp` and `systemd-helper` for minimal embedded footprint

## Compatible AGL Version

- **Scarthgap** (AGL latest)

## Author

Muhammad Tsaqif Mukhayyar — Politeknik Elektronika Negeri Surabaya (PENS)
