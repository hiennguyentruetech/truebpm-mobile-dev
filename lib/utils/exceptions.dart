/// Custom exceptions for the application
/// These exceptions are used to represent specific error scenarios
/// that can occur during API calls and other operations.

/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  
  AppException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when there is a server error
class ServerException extends AppException {
  ServerException(super.message);
}

/// Exception thrown when there is a network error
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  NotFoundException(super.message);
}

/// Exception thrown when there is an authentication error
class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

/// Exception thrown when there is an authorization error
class AuthorizationException extends AppException {
  AuthorizationException(super.message);
}

/// Exception thrown when there is an invalid response format
class InvalidResponseFormatException extends AppException {
  InvalidResponseFormatException(super.message);
}

/// Exception thrown when there is a validation error
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Exception thrown when there is a conflict (e.g., resource already exists)
class ConflictException extends AppException {
  ConflictException(super.message);
}