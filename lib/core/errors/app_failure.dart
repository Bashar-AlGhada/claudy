sealed class AppFailure {
  const AppFailure();
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({required this.message});
  final String message;
}

class RateLimitFailure extends AppFailure {
  const RateLimitFailure({required this.retryAfter});
  final Duration? retryAfter;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({required this.message});
  final String message;
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({required this.message});
  final String message;
}

