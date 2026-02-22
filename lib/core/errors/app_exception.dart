sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class HttpException extends AppException {
  const HttpException(super.message, {this.statusCode});
  final int? statusCode;
}

class MappingException extends AppException {
  const MappingException(super.message);
}

class ConfigurationException extends AppException {
  const ConfigurationException(super.message);
}
