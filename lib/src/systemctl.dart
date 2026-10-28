import 'dart:io';

import 'service_identity.dart';

const systemctlExecutable = '/usr/bin/systemctl';

List<String> systemctlArguments(String action, {String? remote, String? user}) {
  if (!const ['start', 'stop', 'status', 'enable', 'daemon-reload']
      .contains(action)) {
    throw const FormatException('Unsupported systemctl action');
  }
  if (user != null &&
      RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.-]*$').stringMatch(user) != user) {
    throw const FormatException('Unsupported local user name');
  }
  if ((action == 'daemon-reload') != (remote == null)) {
    throw const FormatException('Unexpected systemctl remote argument');
  }
  return [
    if (user != null) '--machine=$user@.host',
    '--user',
    '--no-pager',
    action,
    if (remote != null) serviceName(remote),
  ];
}

/// Explicit argv, with both output streams and the original exit status.
int runSystemctl(String action, {String? remote, String? user}) {
  final result = Process.runSync(systemctlExecutable,
      systemctlArguments(action, remote: remote, user: user),
      stdoutEncoding: null, stderrEncoding: null);
  stdout.add(result.stdout as List<int>);
  stderr.add(result.stderr as List<int>);
  return result.exitCode;
}
