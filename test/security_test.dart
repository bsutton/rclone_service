#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:rclone/src/commands/install.dart';
import 'package:rclone/src/commands/start.dart';
import 'package:rclone/src/commands/status.dart';
import 'package:rclone/src/commands/stop.dart';
import 'package:rclone/src/create_service_file.dart';
import 'package:rclone/src/service_identity.dart';
import 'package:rclone/src/systemctl.dart';

int checks = 0;
// A positional condition keeps these assertions readable like assert().
// ignore: avoid_positional_boolean_parameters
void check(bool condition, String description) {
  checks++;
  if (!condition) {
    throw StateError(description);
  }
}

void rejects(void Function() action, String description) {
  try {
    action();
  } on FormatException {
    checks++;
    return;
  }
  throw StateError('Accepted $description');
}

// Pure checks only: never invoke a command, filesystem writer or privilege API.
void main() {
  final parser = ArgParser()..addFlag('verbose');
  check(
      serviceFilePath('/passwd/home/alice', 'Drive:') ==
          '/passwd/home/alice/.config/systemd/user/rclone-service-Drive.service',
      'unit path uses supplied passwd home and normalized remote');
  check(
      serviceFilePath('/passwd/home/bob', 'Backup') ==
          '/passwd/home/bob/.config/systemd/user/rclone-service-Backup.service',
      'unit path follows supplied passwd home independently of process HOME');
  for (final value in ['Drive', 'a_1-b', '9', 'Drive:']) {
    final expected = value == 'Drive:' ? 'Drive' : value;
    check(validateRemote(value) == expected, 'remote normalization');
    final args = parser.parse(['--', value]);
    check(StartArgs.from(args).remoteName == expected, 'start normalization');
    check(StopArgs.from(args).remoteName == expected, 'stop normalization');
    check(StatusArgs.from(args).remoteName == expected, 'status normalization');
    check(
        InstallArgs.from(parser.parse(['--', value, '/mnt/drive']))
                .remoteName ==
            expected,
        'install normalization');
  }
  final badRemotes = [
    '',
    ':',
    'a::',
    '-a',
    '../outside',
    '/tmp/outside',
    'a/b',
    'a.b',
    'a b',
    'a --system',
    'a*',
    'a?',
    'a[1]',
    r'a\x20',
    'a@b',
    'a%h',
    r'a$HOME',
    'a"',
    "a'",
    'a;',
    'a\n',
    'a\r',
    'a\r\n',
    'a\x00',
    'é',
    List.filled(129, 'a').join()
  ];
  for (final value in badRemotes) {
    rejects(() => validateRemote(value), 'remote $value');
    final args = parser.parse(['--', value]);
    rejects(() => StartArgs.from(args), 'start remote');
    rejects(() => StopArgs.from(args), 'stop remote');
    rejects(() => StatusArgs.from(args), 'status remote');
    rejects(() => InstallArgs.from(parser.parse(['--', value, '/mnt/a'])),
        'install remote');
    rejects(() => getContent(remoteName: value, pathToMountPoint: '/mnt/a'),
        'generated remote');
    rejects(() => systemctlArguments('start', remote: value), 'argv remote');
  }
  for (final value in ['/mnt/drive', '/home/user/.mounts/a-b_2']) {
    check(validateMountPath(value) == value, 'valid absolute path');
  }
  for (final value in [
    '',
    '/',
    'relative',
    '~/drive',
    '/a/../b',
    '/a/./b',
    '//a',
    '/a/',
    '/a b',
    '/a\n[Service]\nExecStartPre=/usr/bin/true',
    '/a%h',
    r'/a$HOME',
    '/a"',
    "/a'",
    r'/a\b',
    '/a;',
    '/a\n',
    '/a\r',
    '/a\r\n',
    '/a\x00'
  ]) {
    rejects(() => validateMountPath(value), 'mount path');
    rejects(() => InstallArgs.from(parser.parse(['--', 'a', value])),
        'install mount');
    rejects(() => getContent(remoteName: 'a', pathToMountPoint: value),
        'generated mount');
  }
  for (final action in ['start', 'stop', 'status', 'enable']) {
    final argv = systemctlArguments(action, remote: 'Drive:');
    check(
        argv.join('|') ==
            '--user|--no-pager|$action|rclone-service-Drive.service',
        'exact unit and argv mapping');
    check(
        systemctlArguments(action, remote: 'Drive', user: 'alice').first ==
            '--machine=alice@.host',
        'machine target');
  }
  check(systemctlExecutable == '/usr/bin/systemctl', 'absolute executable');
  check(
      systemctlArguments('daemon-reload', user: 'alice').join('|') ==
          '--machine=alice@.host|--user|--no-pager|daemon-reload',
      'reload argv');
  rejects(() => systemctlArguments('destroy', remote: 'a'), 'unknown verb');
  rejects(() => systemctlArguments('start'), 'missing remote');
  rejects(
      () => systemctlArguments('daemon-reload', remote: 'a'), 'extra remote');
  for (final user in ['a --system', 'a@b', 'a\n', 'a\r', 'a\r\n', 'a\x00']) {
    rejects(
        () => systemctlArguments('daemon-reload', user: user), 'user target');
  }
  final first = getContent(remoteName: 'A', pathToMountPoint: '/mnt/a');
  final second = getContent(remoteName: 'B', pathToMountPoint: '/mnt/b');
  check(serviceName('A') != serviceName('B'), 'distinct instance files');
  check(!serviceName('A').contains('@'), 'no legacy template fallback');
  check(first.contains(' A: /mnt/a\n') && second.contains(' B: /mnt/b\n'),
      'distinct bindings');
  check(first.contains('ExecStop=/bin/fusermount -u /mnt/a\n'), 'stop binding');
  check(existingServiceMatches(first, first), 'idempotent install');
  check(
      !existingServiceMatches(
          first, getContent(remoteName: 'A', pathToMountPoint: '/mnt/other')),
      'conflicting mount rejected');
  check(!existingServiceMatches(first, second), 'conflicting remote rejected');
  check(
      !first.contains('allow-other') &&
          !first.contains('/tmp/') &&
          first.contains('--umask 077') &&
          first.contains('UMask=0077') &&
          first.contains('StandardError=journal'),
      'private defaults');
  check(
      first.split('\n').where((line) => line.startsWith('ExecStart=')).length ==
          1,
      'single ExecStart');
  print(green('$checks pure security checks passed'));
}
