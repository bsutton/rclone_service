import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:posix/posix.dart';

import '../create_service_file.dart';
import '../exit_exception.dart';
import '../search_file.dart';

class InstallCommand extends Command<int> {
  InstallCommand() {
    argParser.addFlag('verbose', abbr: 'v', help: 'enable verbose logging');
  }
  @override
  String get description => '''
Install rclone as a service.

install <remote> <local mount point>''';

  @override
  String get name => 'install';
  @override
  int run() {
    final args = InstallArgs.from(argResults!);

    if (!Shell.current.isPrivilegedUser) {
      throw ExitException(1, 'You must run as a privileged user');
    }

    Shell.current.releasePrivileges();
    configureFuse();

    createServiceFile(args);

    createMountPoint(args);

    final user = getUserNameByUID(geteuid());

    Shell.current.withPrivileges(() {
      // cause our new service to be loaded.
      'systemctl --machine=$user@.host --user daemon-reload'.run;
      'systemctl --machine=$user@.host --user enable rclone@GDrive'.run;
    });

    return 0;
  }
}

void createMountPoint(InstallArgs args) {
  if (!exists(args.localPathToRemote)) {
    createDir(args.localPathToRemote, recursive: true);
  }
}

// Added `user_allow_other to the fuse file.
void configureFuse() {
  Shell.current.withPrivileges(() {
    final pathToFuse = join(rootPath, 'etc', 'fuse.conf');

    Settings().verbose('path: $pathToFuse');

    if (!exists(pathToFuse)) {
      touch(pathToFuse);
    }

    final search = Search(pathToFuse);
    const allowOther = 'user_allow_other';
    if (search.search('#$allowOther') == true) {
      replace(pathToFuse, '#$allowOther', allowOther);
    } else {
      if (search.search(allowOther) == true) {
        // already enabled
        return;
      } else {
        pathToFuse.append(allowOther);
      }
    }
  });
}

class InstallArgs {
  InstallArgs.from(ArgResults results) {
    if (results.rest.length != 2) {
      throw ExitException(
          1,
          'The install command expects two arguments, '
          'found: ${results.rest.length}');
    }
    remoteName = results.rest[0];
    localPathToRemote = results.rest[1];

    Settings().setVerbose(enabled: results['verbose'] as bool);
  }

  late final String remoteName;
  late final String localPathToRemote;
}
