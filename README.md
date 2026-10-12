# meta-agl-app-store

Yocto/BitBake meta layer for the **AGL PENS App Store** — a Flutter-based embedded application store for Automotive Grade Linux (AGL) with Flatpak support.

Target release: **AGL `trout`** (Yocto 5.0 *scarthgap*, poky 5.0.15).

## Overview

This layer provides:

1. **Flutter App Store recipe** (`agl-app-store.bb`) — builds the [AGL App Store](https://github.com/mukhayyar/agl-app-store) Flutter embedded client
2. **Flatpak packagegroup** (`packagegroup-flatpak.bb`) — pulls in flatpak, ostree, gnupg, ca-certificates, glib-networking
3. **Pre-configured repositories** (`flatpak-predefined-repos.bb`) — registers **PENSHub** and **Flathub** on first boot with GPG verification
4. **Platform integration** (`packagegroup-agl-demo-platform-flutter.bbappend`) — adds the app to the AGL IVI launcher
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
│           └── agl-app-flutter@agl_app_store.service  # systemd unit (name must match AGL_APP_ID)
├── recipes-core/
│   └── packagegroups/
│       └── packagegroup-flatpak.bb         # Flatpak + OSTree + deps
├── recipes-flatpak/
│   └── flatpak-predefined-repos/
│       ├── flatpak-predefined-repos.bb     # First-boot repo setup service
│       ├── rotate-penshub-gpg.sh           # Refresh the bundled PENSHub key
│       └── files/
│           ├── setup-flatpak-repos.sh      # Registers PENSHub + Flathub with GPG
│           └── penshub-public.gpg
└── recipes-platform/
    └── packagegroups/
        └── packagegroup-agl-demo-platform-flutter.bbappend  # Adds app to IVI
```

## Layer Dependencies

| Layer (collection) | Purpose |
|---|---|
| `core` | OE-Core base |
| `openembedded-layer` (meta-oe) | `flatpak` 1.15.8, `ostree` 2024.5, `gnupg`, `glib-networking` |
| `flutter-layer` (meta-flutter) | Flutter embedder (`flutter-auto`) + `flutter-app` class |
| `agldemo` (meta-agl-demo) | host layer of `packagegroup-agl-demo-platform-flutter` |
| `meta-app-framework` | AGL application framework (`agl-app` class, `applaunchd`) |

> **Note:** This layer does **not** bundle its own `flatpak_git.bb` or `ostree_git.bb`.
> In AGL trout both come from `meta-openembedded/meta-oe` — no `meta-flatpak` layer is
> part of the AGL manifest, and none is needed.

## Setup

### 1. Gather AGL sources and set up build environment

```bash
repo init -b trout -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
repo sync -j8
source meta-agl/scripts/aglsetup.sh -m raspberrypi4 -b build-rpi4 agl-demo agl-devel
```

### 2. Add this layer to `bblayers.conf`

```
# Required: dconf (a hard DEPENDS of meta-oe's flatpak) comes from meta-gnome
BBLAYERS += "${METADIR}/external/meta-openembedded/meta-gnome"

# Add our layer
BBLAYERS += "${METADIR}/external/meta-agl-app-store"
```

### 3. (Optional) Use the distro include for full Flatpak config

Add to `local.conf`:

```bash
include conf/distro/include/agl-app-store-flatpak.inc
```

This sets:

- `IMAGE_INSTALL:append = " flatpak agl-app-store"`
- `IMAGE_ROOTFS_EXTRA_SPACE:append = " + 4000000"` (~4 GB for apps/runtimes)
- `DISTRO_FEATURES:append = " polkit wayland seccomp x11"`

`polkit` is not optional: `meta-oe`'s `flatpak_1.15.8.bb` declares
`REQUIRED_DISTRO_FEATURES = "polkit"` and the build fails without it. `x11`
is needed for `xwayland` so legacy X11 flatpak apps can render on AGL's
Wayland compositor (`x11` also auto-enables flatpak's `xauth`
PACKAGECONFIG).

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
| **penshub** | `https://repo.agl-store.cyou` | Key bundled in the image (`/usr/share/flatpak-predefined-repos/penshub-public.gpg`) |
| **flathub** | `https://dl.flathub.org/repo/flathub.flatpakrepo` | Key embedded in the `.flatpakrepo` file |

The `org.gnome.Platform//46` shared runtime is also installed from Flathub if network is available.

## Security & GPG Verification

The PENSHub remote is added **with GPG verification enabled**. On first boot:

1. The setup script imports the public key that is already shipped in the image
   by `flatpak-predefined-repos.bb` (no network fetch, so a failed download can
   never leave penshub registered as a non-verified remote)
2. `flatpak remote-add --system --gpg-import=<key> penshub <url>`
3. If the bundled key is missing the setup is deferred to the next boot

No `--no-gpg-verify` is used. The bundled key is refreshed with
`recipes-flatpak/flatpak-predefined-repos/rotate-penshub-gpg.sh` whenever the
PENSHub signing key rotates.

## Testing Flatpak on the image

After booting, verify Flatpak works via SSH or serial:

```bash
# Check remotes are configured
flatpak remote-list --system

# List available apps from PENSHub
flatpak remote-list --system --show-details
flatpak remote-ls --system penshub

# Install an app from PENSHub
flatpak install --system penshub com.pens.Calculator

# Run it
flatpak run com.pens.Calculator
```

## Application unit

`agl-app-store.bb` installs `agl-app-flutter@agl_app_store.service`.
The name is not arbitrary: the `agl-app` class creates the instance symlink
`<AGL_APP_TEMPLATE>@<AGL_APP_ID>.service` (`AGL_APP_ID = "agl_app_store"`) and
`applaunchd` starts the application under that instance name. The unit's
`ExecStart` uses the bundle layout produced by the `flutter-app` class:

```
/usr/bin/flutter-auto -b /usr/share/flutter/agl_app_store/${FLUTTER_VERSION}/${FLUTTER_RUNTIME} --xdg-shell-app-id agl_app_store
```

`FLUTTER_VERSION` / `FLUTTER_RUNTIME` are read from `/etc/default/flutter`
(shipped by `agl-flutter-env`).

The store is normally started on demand from the AGL launcher. To auto-start it
at boot, uncomment the two `SYSTEMD_SERVICE` / `SYSTEMD_AUTO_ENABLE` lines in the
recipe.

## Production Notes

- `SRCREV` in `agl-app-store.bb` is pinned — bump it when the application changes
- The application repository has no `pubspec.lock` matching the Yocto Flutter
  SDK, which is why the recipe sets `PUBSPEC_IGNORE_LOCKFILE = "1"`:
  `meta-flutter` then regenerates the lockfile with the SDK's own tooling
- Adjust `IMAGE_ROOTFS_EXTRA_SPACE` based on target storage (~4 GB default)
- Wayland apps from Flathub work out of the box with the AGL compositor
- Qt apps from Flathub need: `flatpak run --env=QT_QPA_PLATFORM=wayland <app-id>`

## Compatible AGL Version

- **trout** (Yocto 5.0 *scarthgap*, poky 5.0.15)
-  Older layers were built against previous AGL releases; only trout is
  supported by this revision of the layer.

## Author

Muhammad Tsaqif Mukhayyar — Politeknik Elektronika Negeri Surabaya (PENS)
