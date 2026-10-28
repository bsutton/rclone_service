import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../exit_exception.dart';
import '../service_identity.dart';
import '../systemctl.dart';

class StartCommand extends Command<int> {
  @override
  String get description => 'Starts rclone as a service';

  @override
  String get name => 'start';

  @override
  int run() {
    final args = StartArgs.from(argResults!);

    return runSystemctl('start', remote: args.remoteName);
  }
}

class StartArgs {
  StartArgs.from(ArgResults results) {
    if (results.rest.length != 1) {
      throw ExitException(
          1,
          'The start command expects an rclone remote name as an argument. '
          'Found: ${results.rest.length}');
    }
    remoteName = validateRemote(results.rest[0]);
  }

  late final String remoteName;
}
