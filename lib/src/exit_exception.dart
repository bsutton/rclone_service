class ExitException implements Exception {
  ExitException(this.exitCode, this.message);

  int exitCode;
  String message;
}
