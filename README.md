# Intel MacBook Development Setup Guide

**A small, community-minded toolkit for keeping Intel Macs useful.**

macOS 26 (Tahoe) is the last macOS release that supports Intel Macs ([Apple announced this at WWDC 2025](https://sixcolors.com/post/2025/06/macos-tahoe-is-the-last-release-to-support-intel/)). These machines are still capable, but the tools around them are slowly shifting: [Homebrew has moved Intel to its reduced-support Tier 3](https://docs.brew.sh/Support-Tiers), prebuilt packages are getting scarcer, and some projects stopped publishing Intel macOS builds (PyTorch's [last Intel wheels were 2.2.x](https://dev-discuss.pytorch.org/t/pytorch-macos-x86-builds-deprecation-starting-january-2024/1690)).

I started this repo to make my own 2019 MacBook Pro easier to live with, and I'm sharing it in case it helps you too. It's a work in progress, it's been tried on exactly one machine so far, and it will get better with your experience.

| Script | What it does |
|---|---|
| `setup-mac.sh` | Sets up a modern dev environment from package lists you can edit |
| `health-check.sh` | A one-screen look at battery, throttling, memory, disk and busy processes |
| `verify-setup.sh` | Checks your shell config and that your tools are found in every kind of shell |
| `uninstall-mac.sh` | Removes what the setup installed, group by group |

There's also a [field guide](docs/TIPS.md) of tips and an [Intel compatibility table](docs/COMPATIBILITY.md).

> **Where this has been tested:** MacBook Pro 16" 2019 (i9, 32 GB, macOS 26). Other Intel Macs *should* work, but I can't promise it. If you try it on a different model, please tell us how it went, good or bad.

---

## Getting started

```sh
xcode-select --install                  # 1. compiler basics (skip if already installed)
# 2. install MacPorts: pick the .pkg for your macOS at macports.org/install.php
git clone https://github.com/anandi1989/Intel-macbook-dev-setup-guide.git
cd Intel-macbook-dev-setup-guide
./setup-mac.sh --dry-run                # 3. preview first: changes nothing, asks for no password
./setup-mac.sh                          # 4. run it for real
```

Then open a **new** terminal tab and check how things went:

```sh
./verify-setup.sh     # PASS/WARN/FAIL for your shell config, PATH and tools
./health-check.sh     # battery, throttling, memory, disk
```

A few honest expectations:

- It can take **30-90 minutes**. Some packages compile from source, and compiling is the hardest thing you can ask of an Intel laptop. The fans will spin up.
- Please **plug in the charger** and give the laptop some air (a stand helps).
- You'll be asked for your **password** during the `sudo` steps. That's why we suggest reading the script and trying `--dry-run` first.

### Choosing what to install

```sh
./setup-mac.sh base runtimes     # name any groups you like
./setup-mac.sh all               # every group
```

| Group | Includes | By default? |
|---|---|---|
| `base` | git, gh, lazygit, tmux, neovim, ripgrep, fd, bat, fzf, jq, yq, httpie, wget, direnv, btop, ncdu, dust, mise | yes |
| `c` | cmake, ninja, meson, pkgconfig, ccache, clang-19, llvm-19, Bear, doxygen, lcov | yes |
| `runtimes` | Python 3.13, uv, Go, Rust, Java (Temurin 21), Zig (mostly prebuilt, via mise) | yes |
| `js` | Node LTS, pnpm, Bun, Deno, TypeScript, tsx, Biome | yes |
| `containers` | Colima, docker, docker-compose (a lighter alternative to Docker Desktop) | no |
| `db` | SQLite, PostgreSQL 16, Redis | no |
| `ios` | xcodes, swiftlint, swiftformat, xcbeautify (Xcode itself comes from the App Store) | no |
| `ml` | JupyterLab and ruff as isolated uv tools (CPU-friendly) | no |

The package lists live in [`groups/`](groups) as plain text, so you can change what gets installed without touching the script. If a package name doesn't work on your macOS version, removing that line and re-running is safe. You can look names up with `port search <name>` or `mise ls-remote <name>`.

Changed your mind? `./uninstall-mac.sh --dry-run base` shows what would be removed; leave off `--dry-run` to do it. It only touches packages named in `groups/`.

---

## Why MacPorts and mise?

This is a judgment call, not a verdict on Homebrew. Homebrew still works on Intel for now (existing bottles may keep working, with removal planned for 2027 according to secondary reports), and nothing here stops you from using it. We chose differently because Tier 3 means no new prebuilt bottles, which tends to mean more building from source, and on a laptop that means heat and waiting.

- **MacPorts** has supported Intel for a long time, provides prebuilt archives for supported macOS versions, and keeps everything under `/opt/local`.
- **mise** manages language versions per project and mostly downloads upstream prebuilt binaries, so you skip many long compiles.

One caveat we ran into ourselves: some MacPorts ports, including `mise`, can still compile from source. It's slow, but it works.

---

## Two checks you can run any time

**`./health-check.sh`** is read-only, needs no sudo, and prints no serial numbers, so its output is safe to paste into an issue. It looks at battery wear, CPU throttling, memory pressure, free disk, runaway processes and missing tools. For example:

```
Battery
  [WARN] Health  : 78% of design capacity (6881 / 8790 mAh), consider a replacement soon
Thermals
  [ BAD] CPU speed limited to 32% (thermal throttling right now; heavy build or hot room?)
```

**`./verify-setup.sh`** is also read-only. It checks that `~/.zprofile` and `~/.zshrc` parse and contain the setup blocks, that your tools are found in a new Terminal tab, in a VS Code-style terminal and in a login shell used by scripts, that PATH has no duplicates, and that `mise doctor` is happy. You can name your own tools: `./verify-setup.sh node tsc rustc`.

---

## Known rough edges

We'd rather tell you than have you find out:

- The scripts have been run for real on **one machine**. The package lists are checked against MacPorts, but not every name has been tried on every macOS version.
- The [compatibility notes](docs/COMPATIBILITY.md) are now sourced from web research (reviewed 2026-11-21), but this area changes quickly, and a few rows (MacPorts coverage, Docker, Xcode) are marked unverified. Please check them against the linked sources.
- `uninstall-mac.sh` is the least tested script. Run it with `--dry-run` first.
- Setup doesn't yet resume cleanly after a failure midway. Re-running is safe, but it starts from the top.

## Help us improve it

This only gets good with more machines and more eyes. Some easy ways to help:

- **Tell us what happened on your Mac.** Open an issue with your model, macOS version and the output of `./health-check.sh` and `./verify-setup.sh`.
- **Fix a package name** in `groups/` that doesn't work for you.
- **Add a tip** for your specific model to the [field guide](docs/TIPS.md).
- **Correct something** that's wrong or out of date. Nobody minds, and we'd be grateful.

The details are in [CONTRIBUTING.md](CONTRIBUTING.md). Beginners are very welcome; a confusing instruction is a bug in the docs, not in you.

## Docs

- [Field guide](docs/TIPS.md): heat, busy processes, battery, disk, containers, ML and iOS on Intel, and planning a move to Apple Silicon
- [Compatibility notes](docs/COMPATIBILITY.md): what still works on Intel, with dates
- [Contributing](CONTRIBUTING.md)

## A note before you run anything

`setup-mac.sh` installs software and uses `sudo`. Please read it first (it's short) and try `--dry-run`. It comes with no warranty, so use it at your own risk. Licensed under the [MIT License](LICENSE).
