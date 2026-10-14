enum StartupStatus { loading, ready, failed }

class StartupState {
  const StartupState(this.status, {this.message});
  final StartupStatus status;
  final String? message;
}
