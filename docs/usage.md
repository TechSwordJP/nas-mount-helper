# Usage

## Local run

If you cloned the repository on a Jetson device, run:

```bash
./src/bin/nas-mount-helper
```

## Release distribution

This project publishes `setup.sh` and `payload.tar.gz` as GitHub Release assets.

Users run:

```bash
curl -fsSL https://github.com/<owner>/<repo>/releases/latest/download/setup.sh | sh
```

## Release flow

1. Push a tag such as `v2026.04.10`
2. Or run the `Release` GitHub Actions workflow manually with a tag value
3. GitHub Actions builds `setup.sh` and `payload.tar.gz`
4. GitHub Releases publishes both assets and writes a Japanese usage guide into the release body
5. Users open the release page, copy the command, and run it on the Jetson device
6. `setup.sh` downloads `payload.tar.gz`, expands it into a temp directory, runs the setup wizard, and exits
