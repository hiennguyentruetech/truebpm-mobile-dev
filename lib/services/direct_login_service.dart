import 'package:dio/dio.dart';
import 'package:truebpm/utils/global_store.dart';


/// Service for direct login API calls
class DirectLoginService {
  final Dio _dio;

  DirectLoginService({Dio? dio}) : _dio = dio ?? Dio();

  /// Login with username and password
  /// Returns DirectLoginResult with success/failure status
  Future<DirectLoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final loginUrl = '${hosts.bonitaUrl}loginservice';
      
      // logger.i('Direct API login to: $loginUrl');
      // logger.i('Login payload: username=$username, password=***');
      
      final response = await _dio.post(
        loginUrl,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      // logger.i('Login response status: ${response.statusCode}');
      // logger.i('Login response headers: ${response.headers.map}');
      // logger.i('Login response body: ${response.data}');

      return _handleResponse(response);
    } on DioException catch (e) {
      // logger.e('Login DioException: ${e.message}');
      return _handleDioException(e);
    } catch (e) {
      // logger.e('Unexpected login error: $e');
      return DirectLoginResult.failure(appStrings.unknownError);
    }
  }

  DirectLoginResult _handleResponse(Response response) {
    switch (response.statusCode) {
      case 204:
        // logger.i('Login successful');
        final cookies = response.headers['set-cookie'] ?? [];
        return DirectLoginResult.success(cookies: cookies);
      case 401:
        return DirectLoginResult.failure(appStrings.invalidCredentials);
      case null:
        return DirectLoginResult.failure(appStrings.serverNotResponding);
      default:
        if (response.statusCode! >= 500) {
          return DirectLoginResult.failure(appStrings.serverError);
        }
        return DirectLoginResult.failure('${appStrings.loginFailed} (${response.statusCode})');
    }
  }

  DirectLoginResult _handleDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return DirectLoginResult.failure(appStrings.invalidCredentials);
    } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return DirectLoginResult.failure(appStrings.serverError);
    } else {
      return DirectLoginResult.failure(appStrings.connectionError);
    }
  }
}

/// Result class for direct login operations
class DirectLoginResult {
  final bool isSuccess;
  final String? message;
  final List<String> cookies;

  DirectLoginResult._({
    required this.isSuccess,
    this.message,
    this.cookies = const [],
  });

  factory DirectLoginResult.success({List<String> cookies = const []}) {
    return DirectLoginResult._(
      isSuccess: true,
      cookies: cookies,
    );
  }

  factory DirectLoginResult.failure(String message) {
    return DirectLoginResult._(
      isSuccess: false,
      message: message,
    );
  }
}
