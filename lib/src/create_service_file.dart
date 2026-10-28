import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:posix/posix.dart';

import 'commands/install.dart';
import 'exit_exception.dart';
import 'service_identity.dart';

void createServiceFile(InstallArgs args) {
  final content = getContent(
      remoteName: args.remoteName, pathToMountPoint: args.pathToMountPoint);
  final file =
      File(serviceFilePath(getpwuid(geteuid()).homePathTo, args.remoteName));
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type != FileSystemEntityType.notFound) {
    if (type == FileSystemEntityType.file &&
        existingServiceMatches(file.readAsStringSync(), content)) {
      return;
    }
    throw ExitException(
        1,
        'Service file already exists with different content: ${file.path}. '
        'Review and move it aside manually before reinstalling.');
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content, flush: true);
}

/// Builds the unit path from the effective user's passwd home, not HOME.
String serviceFilePath(String passwdHome, String remote) =>
    join(passwdHome, '.config', 'systemd', 'user', serviceName(remote));

/// An existing instance may only be reused for an identical configuration.
bool existingServiceMatches(String existing, String requested) =>
    existing == requested;

String getContent(
    {required String remoteName, required String pathToMountPoint}) {
  final remote = validateRemote(remoteName);
  final mount = validateMountPath(pathToMountPoint);
  return '''
# Managed by rclone_service; one remote and mount per service file.
[Unit]
Description=rclone remote $remote
Documentation=man:rclone(1)
After=network-online.target
Wants=network-online.target
AssertPathIsDirectory=$mount

[Service]
Type=notify
UMask=0077
ExecStart=/usr/bin/rclone mount --config=%h/.config/rclone/rclone.conf --vfs-cache-mode writes --vfs-cache-max-size 100M --log-level INFO --umask 077 $remote: $mount
ExecStop=/bin/fusermount -u $mount
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
''';
}
