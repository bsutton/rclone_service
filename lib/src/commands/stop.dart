import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../exit_exception.dart';
import '../service_identity.dart';
import '../systemctl.dart';

class StopCommand extends Command<int> {
  @override
  String get description => 'Stop the rclone service';

  @override
  String get name => 'stop';

  @override
  int run() {
    final args = StopArgs.from(argResults!);

    return runSystemctl('stop', remote: args.remoteName);
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
    remoteName = validateRemote(results.rest[0]);
  }

  late final String remoteName;
}
