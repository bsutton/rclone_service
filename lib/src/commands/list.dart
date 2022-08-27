import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';

import '../exit_exception.dart';

class ListCommand extends Command<int> {
  @override
  String get description => 'Lists configured rclone remotes';

  @override
  String get name => 'list';

  @override
  int run() {
    ListArgs.from(argResults!);

    'rclone listremotes'.run;
    return 0;
  }
}

class ListArgs {
  ListArgs.from(ArgResults results) {
    if (results.rest.isNotEmpty) {
      throw ExitException(
          1,
          'The list command does NOT take an argument, '
          'found: ${results.rest.length}');
    }
  }
}
