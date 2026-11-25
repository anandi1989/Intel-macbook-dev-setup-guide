# Intel compatibility notes

Last reviewed: 2026-11-21 (web search). This area changes quickly, so please check the linked sources and send a PR when something goes stale. Entries marked *unverified* are things we believe but could not confirm from a primary source.

| Topic | What we found | Confidence | Source |
|---|---|---|---|
| **macOS** | Apple said at WWDC 2025 that macOS 26 (Tahoe) is the final macOS release for Intel Macs. The Intel models that can run it are the 2019 16" MacBook Pro, the 2020 13" MacBook Pro (four Thunderbolt 3 ports), the 2020 27" iMac and the 2019 Mac Pro. | High (Apple, widely reported) | [Six Colors](https://sixcolors.com/post/2025/06/macos-tahoe-is-the-last-release-to-support-intel/), [Computerworld](https://www.computerworld.com/article/4122798/its-time-to-upgrade-those-old-intel-macs.html) |
| **Security updates for Tahoe** | One outlet reports updates until about fall 2028, but Apple has not formally committed to a date. | Low | [Thurrott](https://www.thurrott.com/?p=321965) |
| **Homebrew** | Homebrew announced Intel macOS moves to Tier 3 (no CI, no new bottles) in September 2026. Its Support Tiers page lists Intel x86_64 as Tier 3 for macOS 11 through 26. Secondary reports say full removal is planned for September 1, 2027. Existing bottles may keep working. | High for Tier 3; medium for the 2027 date | [Homebrew 5.0.0 notes](https://brew.sh/2025/11/12/homebrew-5.0.0), [Support Tiers](https://docs.brew.sh/Support-Tiers) |
| **PyTorch** | 2.2.x was the last release with macOS x86_64 binaries (conda and pip wheels). Newer versions don't install from PyPI on Intel Macs. Building from source is discussed on forums, but we didn't find an official recipe. | High | [PyTorch deprecation notice](https://dev-discuss.pytorch.org/t/pytorch-macos-x86-builds-deprecation-starting-january-2024/1690), [forum thread](https://discuss.pytorch.org/t/why-no-macosx-x86-64-build-after-torch-2-2-2-cp39-none-macosx-10-9-x86-64-whl/204546) |
| **MacPorts** | Has historically supported Intel, including binary archives per macOS release. One recent third-party guide says it carries Intel builds for macOS 11 through 26, but also notes some ports lacked prebuilt Intel builds for Tahoe. We hit this ourselves: `mise` compiled from source. | Medium (primary source not found) | [MacPorts news](https://macports.org/news), [mac.install.guide](https://mac.install.guide/homebrew/macports) |
| **GitHub Actions** | `macos-15-intel` is the current Intel macOS runner label. GitHub's plan is to stop supporting the architecture when the macOS 15 image is retired in fall 2027 (another source says August 2027). | Medium | [GitHub changelog](https://github.blog/changelog/2025-09-19-github-actions-macos-13-runner-image-is-closing-down/) |
| **Docker Desktop** | We recommend Colima as a lighter alternative on Intel. This is our experience-based suggestion, not a verified compatibility statement. | Unverified | none |
| **Xcode** | Check Apple's release notes for the Intel and macOS requirements before downloading. We haven't verified the current one. | Unverified | none |

## What this means in practice

- Your Mac keeps working. The shift is in the ecosystem around it: fewer prebuilt packages, so more compiling, which means heat and waiting.
- For Python ML, treat the Mac as CPU-only and plan on PyTorch 2.2.2 at most for local pip installs, or train in the cloud.
- If a package compiles from source on your Mac, use a charger and a stand. See [TIPS.md](TIPS.md).

## Adding or fixing a row

Please include the date, a link to a primary source where possible, and your confidence. A row we can't source stays marked *unverified*, and that's fine.
