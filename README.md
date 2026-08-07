# Dex

A macOS-only, Apple-Silicon-only fork of [Visual Studio Code](https://github.com/microsoft/vscode), stripped to a single workflow: **files on the left, editor in the middle, terminal on the right.**

Forked from `microsoft/vscode` at **1.126.0** (Code - OSS, MIT), with the [VSCodium](https://github.com/VSCodium/vscodium) community patch set applied. Everything upstream builds for other platforms and deployment shapes has been removed rather than merely disabled, so the tree contains only what a local desktop editor needs.

## What Dex is

| | |
|---|---|
| Target | macOS `darwin-arm64` only — the sole entry in `BUILD_TARGETS` |
| Layout | Explorer left, editor center, terminal in the right Auxiliary Bar. Bottom panel and Activity Bar hidden; views reached via Command Palette |
| Default theme | Aura Dark, bundled as the built-in `theme-aura` extension |
| Extensions | [Open VSX](https://open-vsx.org) gallery — vendor-neutral and licensed for third-party editors, unlike Microsoft's Marketplace. Themes install through the same gallery |
| Identity | `dex` binary, `dex://` protocol, `~/.dex` data folder, `com.dex.dex` bundle |

## What was removed

Windows and Linux packaging — resources, gulpfiles, and all non-arm64 build targets. The remote and server deployments (REH, `code-server`, web workbench), so Dex opens local folders only; Remote-SSH, dev containers, and WSL went with them. Microsoft's CI, compliance tooling, dev container, and agent instructions. Test-only extensions, the smoke/integration/automation/monaco suites, and the component-explorer dev harness.

Kept: `test/unit` (via `scripts/test.sh`) and `test/integration/electron/testrunner`, which 11 built-in extensions import.

## Install

```bash
brew tap 0sage/dex https://github.com/0sage/dex.git
brew install --cask dex
```

Releases are ad-hoc signed, not notarized with an Apple Developer certificate, so Gatekeeper rejects them while the quarantine flag is set. The cask strips that flag in a `preflight` hook, while the app is still staged — once it is in `/Applications`, macOS 15 requires App Management permission to modify the bundle and `xattr` fails with EPERM. Homebrew 6 removed `--no-quarantine`, so the hook is what makes a plain `brew install` work.

Pushing a `v*` tag builds `Dex.app` on an Apple Silicon runner, attaches the zip to a GitHub Release, and repoints `Casks/dex.rb` at it — this repo is its own Homebrew tap.

## Build

Requires Node **24.15.0** (see `.nvmrc`) — `preinstall` rejects other major versions.

```bash
npm install

# development: transpile-only, fastest path to a running app
npm run build-fast
VSCODE_SKIP_PRELAUNCH=1 ./scripts/code.sh

# production: bundled, minified, standalone .app
npm run gulp vscode-darwin-arm64-min     # -> ../VSCode-darwin-arm64/Dex.app
```

`VSCODE_SKIP_PRELAUNCH=1` skips `preLaunch.ts`, which re-verifies node_modules, Electron, and built-in extensions on every launch — roughly 2.4s of redundant work once the tree is set up. Omit it after `npm install` or an Electron bump.

Startup to rendered layout, measured with `--prof-duration-markers ellapsed`: **~1.34s** development, **~0.53s** production. The gap is module loading — 6352 unbundled files versus 27 bundled ones.

## Upstream

MIT licensed, same as Code - OSS. Dex modifies shared build files (`gulpfile.vscode.ts`, `filters.ts`, `dirs.ts`, `preinstall.ts`) and branding in `product.json`, so pulling new upstream releases means reconciling those. For the editor's own documentation, architecture, and issues see [microsoft/vscode](https://github.com/microsoft/vscode) — this fork changes packaging and defaults, not how the editor works.
