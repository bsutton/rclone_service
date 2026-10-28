import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:posix/posix.dart';

import '../create_service_file.dart';
import '../exit_exception.dart';
import '../service_identity.dart';
import '../systemctl.dart';

class InstallCommand extends Command<int> {
  InstallCommand() {
    argParser.addFlag('verbose', abbr: 'v', help: 'enable verbose logging');
  }

  @override
  String get description =>
      'Install rclone as a service: install <remote> <absolute mount path>';

  @override
  String get name => 'install';

  @override
  int run() {
    final privileged = Shell.current.isPrivilegedUser;
    Shell.current.releasePrivileges();
    if (!privileged || geteuid() == 0) {
      throw ExitException(
          1,
          'Run install through sudo from your normal user, '
          'not directly as root.');
    }
    final args = InstallArgs.from(argResults!);
    final user = getUserNameByUID(geteuid());
    systemctlArguments('enable', remote: args.remoteName, user: user);
    createServiceFile(args);
    createMountPoint(args);

    var result = 0;
    try {
      Shell.current.withPrivileges(() {
        result = runSystemctl('daemon-reload', user: user);
        if (result == 0) {
          result = runSystemctl('enable', remote: args.remoteName, user: user);
        }
      });
    } finally {
      // dcli 1.x does not release privileges if its callback throws.
      Shell.current.releasePrivileges();
    }
    return result;
  }
}

void createMountPoint(InstallArgs args) {
  Directory(validateMountPath(args.pathToMountPoint))
      .createSync(recursive: true);
}

class InstallArgs {
  InstallArgs.from(ArgResults results) {
    if (results.rest.length != 2) {
      throw ExitException(
          1, 'Install expects a remote and absolute mount path.');
    }
    remoteName = validateRemote(results.rest[0]);
    pathToMountPoint = validateMountPath(results.rest[1]);
    Settings().setVerbose(enabled: results['verbose'] as bool);
  }

  late final String remoteName;
  late final String pathToMountPoint;
}
