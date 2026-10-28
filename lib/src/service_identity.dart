/// Restricted syntax avoids filesystem traversal and systemd expansion.
String validateRemote(String value) {
  final remote =
      value.endsWith(':') ? value.substring(0, value.length - 1) : value;
  if (remote.length > 128 ||
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').stringMatch(remote) != remote) {
    throw const FormatException(
        'Remote must be 1–128 ASCII letters, digits, underscores or hyphens, '
        'starting with a letter or digit; one trailing colon is optional.');
  }
  return remote;
}

String validateMountPath(String value) {
  if (RegExp(r'^/[A-Za-z0-9_./-]+$').stringMatch(value) != value ||
      value
          .split('/')
          .skip(1)
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const FormatException(
        'Mount path must be an absolute non-root path using ASCII letters, '
        'digits, underscores, hyphens and dots. Empty, dot and parent '
        'components, whitespace and systemd expansion characters '
        'are unsupported.');
  }
  return value;
}

String serviceName(String remote) =>
    'rclone-service-${validateRemote(remote)}.service';
