import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../exit_exception.dart';
import '../service_identity.dart';
import '../systemctl.dart';

class StatusCommand extends Command<int> {
  @override
  String get description => 'Displays the status of the rclone  service';

  @override
  String get name => 'status';

  @override
  int run() {
    final args = StatusArgs.from(argResults!);

    return runSystemctl('status', remote: args.remoteName);
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
    remoteName = validateRemote(results.rest[0]);
  }

  late final String remoteName;
}
