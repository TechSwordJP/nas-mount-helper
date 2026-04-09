# nas-mount-helper

JetPack 5.1 / Ubuntu 20.04 で NAS を `/mnt/...` に永続マウントし、Docker から bind mount で使うためのセットアップツールです。

## Run locally

```bash
./src/bin/nas-mount-helper
```

## Run from GitHub Release

```bash
curl -fsSL https://github.com/<owner>/<repo>/releases/latest/download/setup.sh | sh
```

## Release

```bash
git tag v2026.04.10
git push origin v2026.04.10
```

Or run the `Release` workflow manually from GitHub Actions.

## Docs

- [Usage](docs/usage.md)
- [Architecture](docs/architecture.md)
