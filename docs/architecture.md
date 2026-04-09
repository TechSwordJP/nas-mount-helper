# Architecture

## Goal

Provide a low-maintenance setup tool for JetPack 5.1 / Ubuntu 20.04 that mounts a NAS at `/mnt/...`, keeps it available after reboot, and makes it usable as a Docker bind mount source.

## Approach

- GUI: `zenity`
- Mount mechanism: `mount.cifs`
- Persistence: `/etc/fstab`
- Credentials: `/etc/nas-mount-helper/credentials/*.cred`
- Immediate verification: mount right after writing the config
- Startup recovery: `_netdev`, `nofail`, and `network-online.target` related options

## Source layout

- `src/bin/nas-mount-helper`
  - User-facing wizard
- `src/libexec/nas-mount-helper-apply`
  - Root-side mount and `/etc/fstab` update
- `src/libexec/nas-mount-helper-install-cifs-utils`
  - On-demand `cifs-utils` installer
- `scripts/build-release-assets.sh`
  - Builds release assets for GitHub Releases
- `.github/workflows/release.yml`
  - Publishes `setup.sh` and `payload.tar.gz`

## Setup flow

1. User runs the setup wizard
2. If `cifs-utils` is missing, the wizard installs it via `pkexec`
3. User enters NAS host, share, mount name, and credentials
4. Root-side apply script writes:
   - `/mnt/<name>`
   - credential file with `0600`
   - managed `/etc/fstab` block
5. The tool mounts the share immediately for validation

## Example fstab entry

```fstab
//nas.local/media /mnt/media cifs credentials=/etc/nas-mount-helper/credentials/media.cred,iocharset=utf8,vers=3.0,_netdev,nofail,x-systemd.requires=network-online.target,x-systemd.after=network-online.target,x-systemd.before=docker.service,uid=1000,gid=1000,file_mode=0664,dir_mode=0775 0 0
```

## Constraints

- SMB/CIFS only
- JetPack 5.1 / Ubuntu 20.04 focused
- No persistent app install is required for end users
