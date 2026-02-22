import 'package:claudy/core/errors/app_failure.dart';

sealed class AppResult<T> {
  const AppResult();

  R fold<R>(R Function(AppFailure failure) onFailure, R Function(T value) onSuccess);
}

class Failure<T> extends AppResult<T> {
  const Failure(this.failure);

  final AppFailure failure;

  @override
  R fold<R>(R Function(AppFailure failure) onFailure, R Function(T value) onSuccess) {
    return onFailure(failure);
  }
}

class Success<T> extends AppResult<T> {
  const Success(this.value);

  final T value;

  @override
  R fold<R>(R Function(AppFailure failure) onFailure, R Function(T value) onSuccess) {
    return onSuccess(value);
  }
}

