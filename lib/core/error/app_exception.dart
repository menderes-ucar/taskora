import 'package:flutter/material.dart';

enum AppExceptionType {
  network,
  validation,
  authentication,
  authorization,
  notFound,
  conflict,
  serverError,
  unknown,
  timeout,
  noInternet,
}

class AppException implements Exception {
  final String message;
  final AppExceptionType type;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    required this.type,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;

  String getLocalizedMessage() {
    switch (type) {
      case AppExceptionType.network:
        return 'Network error occurred. Please check your connection.';
      case AppExceptionType.validation:
        return message;
      case AppExceptionType.authentication:
        return 'Authentication failed. Please login again.';
      case AppExceptionType.authorization:
        return 'You don\'t have permission to perform this action.';
      case AppExceptionType.notFound:
        return 'The requested resource was not found.';
      case AppExceptionType.conflict:
        return 'A conflict occurred. Please try again.';
      case AppExceptionType.serverError:
        return 'Server error occurred. Please try again later.';
      case AppExceptionType.timeout:
        return 'Request timed out. Please try again.';
      case AppExceptionType.noInternet:
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  bool get isNetworkError =>
      type == AppExceptionType.network ||
          type == AppExceptionType.noInternet;
  bool get isAuthError => type == AppExceptionType.authentication;
  bool get isServerError => type == AppExceptionType.serverError;
}

class ExceptionFactory {
  static AppException create(dynamic exception, StackTrace stackTrace) {
    if (exception is AppException) {
      return exception;
    }

    if (exception is FormatException) {
      return AppException(
        message: 'Invalid data format: ${exception.message}',
        type: AppExceptionType.validation,
        originalException: exception,
        stackTrace: stackTrace,
      );
    }

    if (exception is TimeoutException) {
      return AppException(
        message: 'Request timeout',
        type: AppExceptionType.timeout,
        originalException: exception,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      message: exception.toString(),
      type: AppExceptionType.unknown,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  static void logError(AppException error) {
    print('❌ ERROR [${error.type}]: ${error.message}');
    if (error.stackTrace != null) {
      print(error.stackTrace);
    }
  }
}

extension AppExceptionExt on AppException {
  void showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getLocalizedMessage()),
        backgroundColor: _getErrorColor(),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color _getErrorColor() {
    switch (type) {
      case AppExceptionType.network:
      case AppExceptionType.noInternet:
        return Colors.orange;
      case AppExceptionType.authentication:
      case AppExceptionType.authorization:
        return Colors.red;
      case AppExceptionType.validation:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}

class TimeoutException implements Exception {}
