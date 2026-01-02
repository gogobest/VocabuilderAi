import 'package:equatable/equatable.dart';

/// Base failure class for application errors
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Failure related to cache operations (Hive)
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Failure for general IO operations
class IOFailure extends Failure {
  const IOFailure(String message) : super(message);
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Failure for not found errors
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Failure for database errors
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

/// Failure for general application errors
class ApplicationFailure extends Failure {
  const ApplicationFailure(String message) : super(message);
} 