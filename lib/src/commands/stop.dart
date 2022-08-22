import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';

import '../exit_exception.dart';

class StopCommand extends Command<int> {
  @override
  String get description => 'Stop the rclone service';

  @override
  String get name => 'stop';

  @override
  int run() {
    final args = StopArgs.from(argResults!);

    'systemctl --user stop rclone@${args.remoteName}'.run;
    return 0;
  }
}

class StopArgs {
  StopArgs.from(ArgResults results) {
    if (results.rest.length != 1) {
      throw ExitException(
          1,
          'The stop command expects one arguments, '
          'found: ${results.rest.length}');
    }
    remoteName = results.rest[0];
  }

  late final String remoteName;
}
