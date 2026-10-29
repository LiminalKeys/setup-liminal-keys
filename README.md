# Setup Liminal Keys CLI

GitHub Action: download and verify the **Liminal Keys CLI** from the public API (`GET /v1/public/cli/versions/{version}` + short-lived blob URL). **No secrets**, no GitHub token.

Pin `version` and `sha256` from the release checksum table below (or from API metadata `assets[].sha256`).

## Usage

```yaml
- uses: LiminalKeys/setup-liminal-keys@v1
  with:
    version: "0.1.10"
    sha256: "c9495db59e9433fcb2ac118b9a4e7d18421714da7d42780a39f6af9899c711d5" # linux-x64 example
```

Then run `liminal-keys` from `PATH` (Windows: `liminal-keys.exe`). Enroll, sign, and unenroll stay in your workflow — this action only installs the binary.

## Pinned SHA-256 (cli-v0.1.10)

| Asset | SHA-256 |
|-------|---------|
| `liminal-keys-linux-x64` | `c9495db59e9433fcb2ac118b9a4e7d18421714da7d42780a39f6af9899c711d5` |
| `liminal-keys-linux-arm64` | `df06f81815d82b6e2ecb31ed9ca031d3c44ce57715d6b7aed17331f95df32815` |
| `liminal-keys-osx-x64` | `12048b3e1c5301a23e4b8a5b001fa900e92af8406f73acf166d82316fe05f06f` |
| `liminal-keys-osx-arm64` | `3a6d08a3bbe9eb3d9edf30d583ea6afe84b9097ac16918f23b1a9224dccb5f42` |
| `liminal-keys-win-x64.exe` | `da8edab391817aea32ee171e5d85ef6891f022c42eba8a78516c105025192211` |

Canonical copy in source tree: [`SHA256SUMS-0.1.10.txt`](SHA256SUMS-0.1.10.txt). Public metadata: `https://api.liminalkeys.com/v1/public/cli/versions/0.1.10`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `version` | yes | — | CLI semver (e.g. `0.1.10`) |
| `sha256` | yes | — | Expected SHA-256 for this runner OS/arch |
| `api-base-url` | no | `https://api.liminalkeys.com` | API base URL (https only) |
