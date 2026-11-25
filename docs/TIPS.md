# Intel Mac field guide

Short, practical, and measured on a 2019 MacBook Pro 16" (i9, 32 GB). Run `./health-check.sh` first to see which sections matter to you.

## Keep it cool
An Intel laptop throttles on heat long before it runs out of power.

- **Lighten the compositor:** System Settings > Accessibility > Display > Reduce transparency and Reduce motion.
- **Mind the second display:** a hot discrete GPU often comes from an external monitor. Try 60 Hz.
- **Give it air:** a stand, clear vents and a yearly dust-out beat any software tweak.
- **Look, don't guess:**
  ```sh
  pmset -g therm                                    # CPU_Speed_Limit below 100 means throttling
  sudo powermetrics --samplers smc,cpu_power,gpu_power -i 2000
  ```
- **Compiling is the worst offender.** A source build such as `rustc` can pin all 16 threads and drop the CPU speed limit sharply. Plug in the charger, raise the laptop, and let it finish.

## Tame the hogs
- **Find the culprit:** `btop`, or `ps -Ao pid,pcpu,pmem,comm -r | head`.
- **Demote, don't kill:** `taskpolicy -b -p <PID>` moves a process to background priority.
- **Shader compilers piling up?** `sudo pkill MTLCompilerService` restarts them. macOS relaunches them on demand.
- **Browsers:** Safari is gentler on heat and battery. In Chrome, enable Memory Saver.
- **VS Code:** exclude `node_modules`, `.git` and build output in `files.watcherExclude` and `search.exclude`. Use *Developer: Open Process Explorer* to find greedy extensions.
- **Updater agents** (Google Keystone and friends) live in `~/Library/LaunchAgents`. Remove ones you don't need.

## Care for the battery
- `sudo pmset -b lowpowermode 1` tames turbo boost on battery.
- Keep Optimized Battery Charging on.
- `./health-check.sh` reports capacity against design capacity. At about 80% or lower, a new battery is the best upgrade you can buy.

## Respect the disk and memory
- Keep 20-30 GB free. Explore with `ncdu` or `dust`.
- Skip RAM "purger" and "cleaner" apps. With low memory pressure they only make apps reload.
- Reboot weekly. If Spotlight churns for a full day, rebuild it: `sudo mdutil -E /`.

## Containers
Prefer **Colima** with a small VM over Docker Desktop:
```sh
./setup-mac.sh containers
colima start --cpu 4 --memory 8
```

## Machine learning on Intel
Intel Macs have no CUDA, and the AMD GPU is not a practical PyTorch or TensorFlow target. Treat the Mac as a **CPU-only workstation**: good for data work, notebooks and small models.

- PyTorch 2.2.x was the last release with Intel macOS binaries, so `pip install torch` on a current version will fail on Intel (see `docs/COMPATIBILITY.md`). Pin `torch==2.2.2` for local CPU work, or train in the cloud.
- Create a venv per project: `uv venv && uv pip install ...`.
- Prototype locally, train in the cloud (Colab, Kaggle, Modal, RunPod or a cloud GPU) and sync with git.
- Local LLMs: small quantized models (about 7B at 4-bit) run on CPU but slowly.

## iOS development
You need full Xcode from the App Store. Check its Intel and macOS requirements before the large download.

- The Simulator is slow on Intel; a real device is better. Close the browser while building.
- Afterwards:
  ```sh
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
  ./setup-mac.sh ios        # xcodes, swiftlint, swiftformat, xcbeautify
  ```

## Planning the move to Apple Silicon
When you eventually migrate, the setup is reproducible:

1. Keep your customised `groups/*` files in git.
2. On the new Mac, install MacPorts or Homebrew and run `./setup-mac.sh all`.
3. Copy dotfiles and project folders; reinstall runtimes with `mise install` from each project's `mise.toml` or `.tool-versions`.
