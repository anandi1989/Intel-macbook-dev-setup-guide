# Contributing

Thanks for helping keep Intel Macs useful.

## Good first contributions
- Fix or add a package name in `groups/*` (check with `port info <name>` or `mise ls-remote <name>`).
- Add a model-specific tip to `docs/TIPS.md` (note the model and macOS version).
- Update `docs/COMPATIBILITY.md` when a tool gains or loses Intel support. Include the date and a source link.
- Add a new group: create `groups/<name>.port` (or `.mise` / `.uv`) and wire it into `setup-mac.sh` and `uninstall-mac.sh`.

## Rules for scripts
- Must run on the stock macOS bash (3.2): no `mapfile`, no associative arrays.
- Every state-changing step must go through `run` so `--dry-run` stays truthful.
- Never print serial numbers or personal data.
- Run `bash -n yourscript.sh` and `./setup-mac.sh --dry-run all` before opening a PR.

## Reporting a problem
Include your Mac model, macOS version, the command you ran and the output of `./health-check.sh`.
