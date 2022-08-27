import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';

import '../exit_exception.dart';

class StatusCommand extends Command<int> {
  @override
  String get description => 'Displays the status of the rclone  service';

  @override
  String get name => 'status';

  @override
  int run() {
    final args = StatusArgs.from(argResults!);

    'systemctl --user status rclone@${args.remoteName}'.run;
    return 0;
  }
}

class StatusArgs {
  StatusArgs.from(ArgResults results) {
    if (results.rest.length != 1) {
      throw ExitException(
          1,
          'The status command expects a Remote name as a single argument, '
          'found: ${results.rest.length}');
    }
    var _remoteName = results.rest[0];

    if (_remoteName.endsWith(':')) {
      _remoteName = _remoteName.substring(0, _remoteName.length - 1);
    }
    remoteName = _remoteName;
  }

  late final String remoteName;
}
