import 'package:dcli/dcli.dart';

import 'commands/install.dart';

void createServiceFile(InstallArgs args) {
  final pathToServiceFile =
      join(HOME, '.config', 'systemd', 'user', 'rclone@.service');

  final dirpath = dirname(pathToServiceFile);
  if (!exists(dirpath)) {
    createDir(dirpath, recursive: true);
  }

  final pathToRemote = join(HOME, args.remoteName);
  if (!exists(pathToRemote)) {
    createDir(pathToRemote, recursive: true);
  }

  if (!exists(pathToServiceFile)) {
    pathToServiceFile.write(getContent(
        remoteName: args.remoteName,
        localPathToRemote: args.localPathToRemote));
  }
}

String getContent(
        {required String remoteName, required String localPathToRemote}) =>
    '''
# User service for Rclone mounting
#
# Place in ~/.config/systemd/user/
# File must include the '@' (ex rclone@.service)
# As your normal user, run 
#   systemctl --user daemon-reload
# You can now start/enable each remote by using rclone@<remote>
#   systemctl --user enable rclone@dropbox
#   systemctl --user start rclone@dropbox

[Unit]
Description=rclone: Remote FUSE filesystem for cloud storage config $remoteName
Documentation=man:rclone(1)
After=network-online.target
Wants=network-online.target 
AssertPathIsDirectory=$localPathToRemote

[Service]
Type=notify
ExecStart= \\
  /usr/bin/rclone mount \\
    --config=%h/.config/rclone/rclone.conf \\
    --vfs-cache-mode writes \\
    --vfs-cache-max-size 100M \\
    --log-level INFO \\
    --log-file /tmp/rclone-$remoteName.log \\
    --umask 022 \\
    --allow-other \\
    $remoteName: $localPathToRemote
ExecStop=/bin/fusermount -u $localPathToRemote

[Install]
WantedBy=default.target
''';
