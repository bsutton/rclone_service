import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';

import '../exit_exception.dart';

class StartCommand extends Command<int> {
  @override
  String get description => 'Starts rclone as a service';

  @override
  String get name => 'start';

  @override
  int run() {
    final args = StartArgs.from(argResults!);

    'systemctl --user start rclone@${args.remoteName}'.run;
    return 0;
  }
}

class StartArgs {
  StartArgs.from(ArgResults results) {
    if (results.rest.length != 1) {
      throw ExitException(
          1,
          'The start command expects one arguments, '
          'found: ${results.rest.length}');
    }
    remoteName = results.rest[0];
  }

  late final String remoteName;
}
