# 1.0.4

- Validate every remote argument consistently (one optional trailing colon).
  Supported names contain 1–128 ASCII letters, digits, underscores or hyphens
  and start with a letter or digit. Mount paths must be absolute, non-root,
  with only ASCII letters, digits, dots, underscores, hyphens and separators;
  empty, `.` and `..` components are rejected. Spaces, quotes, control characters,
  systemd specifiers and variable expansions are deliberately unsupported.
- Invoke `/usr/bin/systemctl` with explicit argument lists and preserve its
  output and exit status. Release install privileges before argument handling
  and ordinary work; always drop privileges after the bounded reload/enable
  scope, including failures. Direct root installation is rejected; use sudo
  from the intended normal user's account.
- Create `rclone-service-REMOTE.service` for each remote. Start, stop, status
  and enable all address that exact file. Reinstalling the same configuration
  is idempotent; an existing different file or symlink is rejected. Changing
  a remote's mount requires manually reviewing and moving its existing unit
  aside before reinstalling. No unrelated HOME/remote directory is created.
- Stop changing `/etc/fuse.conf`, remove `--allow-other`, use umask `077`, and
  send logs to the journal instead of predictable `/tmp` files.
- Add pure regression checks for argument validation, systemctl argv, unit
  identity, conflicting configuration and generated service defaults.
- Update the locked transitive `archive` dependency to patched 3.4.2 (and its
  required `pointycastle` version) to address two high-severity alerts.

Migration is explicit: existing `rclone@.service` templates and their instances
are never used, changed or deleted by this version. Before installing a new
unit, inspect the old template to identify the actual remote and mount it uses.
As the owning normal user, stop and disable each old instance by its exact unit
name (for example `systemctl --user disable --now rclone@Drive.service`). Verify
that its mount is no longer active before installing and starting the new unit;
otherwise old and new services can compete for the same mount. Review or archive
the legacy template yourself after all its instances have been disabled. The
installer does not revert an existing `user_allow_other` setting in
`/etc/fuse.conf`; review that setting manually if no other mounts require it.
New start/stop/status commands operate only on the new unit names, so they cannot
stop legacy services. Installation enables the new service but does not start it.

Source scope: tag `1.0.3` already contained unsafe service-content interpolation,
start/stop/status remote interpolation, shared-template reuse and permissive
FUSE defaults. Commit `8a0a776` after that tag additionally changed privileged
install enablement from hardcoded `GDrive` to the supplied remote. The fetched
OnePub 1.0.3 library files match tag `1.0.3`, so the privileged install-name
interpolation is not attributed to that published version.

# 1.0.3
- Added a list and status command.

# 1.0.2
added executable to pubspec.

# 1.0.1
spelling.

## 1.0.0

- Initial version.
