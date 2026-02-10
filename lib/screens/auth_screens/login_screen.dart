import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/services/services.dart';
import 'package:truebpm/services/device_token_service.dart';
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/di/service_locator.dart';
import 'package:truebpm/utils/auth/auth_utils.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/auth/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, LoginAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  bool _biometricLoginEnabled = false;
  
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = get<AuthService>();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setupAnimations();
    startAnimations();
    await Future.wait([
      _checkBiometricAvailability(),
      _loadSavedCredentials(),
    ]);
  }

  @override
  void dispose() {
    disposeAnimations();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _authService.isBiometricAvailable();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
        });
      }
    } catch (e) {
      // logger.e('Error checking biometric availability: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final results = await Future.wait([
        _authService.getSavedUsername(),
        _authService.isBiometricLoginEnabled(),
      ]);
      
      if (mounted) {
        final savedUsername = results[0] as String?;
        final biometricEnabled = results[1] as bool;
        
        if (savedUsername != null) {
          _usernameController.text = savedUsername;
        }
        
        setState(() {
          _biometricLoginEnabled = biometricEnabled;
        });
      }
    } catch (e) {
      // logger.e('Error loading saved credentials: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      print('Starting biometric authentication...');
      if (!mounted) return;
      
      // Add small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Don't show loading immediately to avoid UI conflicts with biometric dialog
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      print('Biometric authentication result: $isAuthenticated');
      
      if (!mounted) return;

      if (isAuthenticated) {
        print('Biometric success, logging in with saved credentials...');
        context.showLoading(message: appStrings.signingIn);
        await _loginWithSavedCredentials();
      } else {
        print('Biometric authentication was not successful');
        // Only show error if user didn't just cancel
        final errorInfo = _authService.getLastBiometricError();
        print('Last biometric error: $errorInfo');
        
        // Don't show error for user cancellation
        if (errorInfo['code'] != 'NotAvailable' && 
            errorInfo['code'] != 'UserCanceled' &&
            errorInfo['code'] != 'SystemCanceled') {
          _setErrorMessage('Xác thực sinh trắc học thất bại. Vui lòng thử lại.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      context.hideLoading();
      print('Biometric authentication error: $e');
      print('Error type: ${e.runtimeType}');
      _setErrorMessage('Lỗi xác thực sinh trắc học. Vui lòng thử lại.');
    }
  }

  Future<void> _loginWithSavedCredentials() async {
    try {
      context.showLoading(message: appStrings.signingIn);

      final result = await _authService.loginWithSavedCredentials();

      if (!mounted) return;

      if (result.isSuccess) {
        // Fetch and save Bonita user info first
        context.showLoading(message: 'Loading Bonita session...');
        await _authService.fetchAndSaveBonitaUserInfo(cookies: result.cookies);
        if (!mounted) return;

        // Then fetch and save user info with cookies
        final savedUsername = await _authService.getSavedUsername();
        if (savedUsername != null) {
          context.showLoading(message: appStrings.loadingUserInfo);
          await _authService.fetchAndSaveUserInfo(savedUsername, cookies: result.cookies);
          if (!mounted) return;
        }
        context.hideLoading();

        // Save device token silently (fire-and-forget) - không block UI
        _saveDeviceTokenSilently(cookies: result.cookies);

        _navigateToMainScreen();
      } else {
        context.hideLoading();
        _setErrorMessage(result.message ?? appStrings.loginFailed);
      }
    } catch (e) {
      if (!mounted) return;
      context.hideLoading();
      // logger.e('Error logging in with saved credentials: $e');
      _setErrorMessage(appStrings.credentialsLoadError);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    _setErrorMessage(null);

    try {
      if (!mounted) return;
      context.showLoading(message: appStrings.signingIn);

      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final result = await _authService.loginDirect(
        username: username,
        password: password,
        enableBiometric: _isBiometricAvailable && !_biometricLoginEnabled,
      );

      if (!mounted) return;
      context.hideLoading();

      if (result.isSuccess) {
        // logger.i('Login successful: ${result.message}');

        // Fetch and save Bonita user info first
        context.showLoading(message: 'Loading Bonita session...');
        await _authService.fetchAndSaveBonitaUserInfo(cookies: result.cookies);
        if (!mounted) return;

        // Then fetch and save user info with cookies
        context.showLoading(message: appStrings.loadingUserInfo);
        await _authService.fetchAndSaveUserInfo(username, cookies: result.cookies);
        if (!mounted) return;
        context.hideLoading();

        // If biometric became available after initial async check or user logged in very fast
        // Force ensure biometric is enabled for next launch (deterministic)
        final recheckAvailable = await _authService.isBiometricAvailable();
        if (recheckAvailable) {
          await _authService.enableBiometricForCredentials(username, password);
          if (mounted) {
            setState(() { _biometricLoginEnabled = true; });
          }
        }

        // Save device token silently (fire-and-forget) - không block UI
        _saveDeviceTokenSilently(cookies: result.cookies);

        _navigateToMainScreen();
      } else {
        _setErrorMessage(result.message ?? appStrings.loginFailed);
      }
    } catch (e) {
      if (!mounted) return;
      context.hideLoading();
      // logger.e('Login error: $e');
      _setErrorMessage(appStrings.connectionError);
    }
  }

  void _setErrorMessage(String? message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _navigateToMainScreen() {
    if (mounted) {
      NavigationService.replaceWith(AppRoutes.mainTab);
    }
  }

  /// Lưu device token (FCM) lên server ngầm sau khi login thành công.
  /// Fire-and-forget: không block UI, không show message lỗi.
  void _saveDeviceTokenSilently({List<String>? cookies}) {
    _authService.getSavedUserInfo().then((userInfo) {
      if (userInfo != null && userInfo.id.isNotEmpty) {
        DeviceTokenService.instance.saveDeviceToken(
          userId: userInfo.id,
          cookies: cookies,
        );
      }
    }).catchError((_) {
      // Ignore - chạy ngầm
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              LoginBackground(
                backgroundOpacityAnimation: backgroundOpacityAnimation,
                constraints: constraints,
              ),
              
              // Content
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 
                            MediaQuery.of(context).padding.vertical,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            
                            // Animated Logo with glow effect
                            AnimatedLogo(
                              logoAnimationController: logoAnimationController,
                              logoScaleAnimation: logoScaleAnimation,
                              logoSlideAnimation: logoSlideAnimation,
                              logoGlowAnimation: logoGlowAnimation,
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Welcome Text
                            AnimatedBuilder(
                              animation: formAnimationController,
                              builder: (context, child) {
                                return WelcomeText(
                                  formOpacityAnimation: formOpacityAnimation,
                                  formSlideAnimation: formSlideAnimation,
                                );
                              },
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Login Form
                            AnimatedBuilder(
                              animation: formAnimationController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: formOpacityAnimation,
                                  child: SlideTransition(
                                    position: formSlideAnimation,
                                    child: LoginForm(
                                      formKey: _formKey,
                                      usernameController: _usernameController,
                                      passwordController: _passwordController,
                                      obscurePassword: _obscurePassword,
                                      errorMessage: _errorMessage,
                                      isBiometricAvailable: _isBiometricAvailable,
                                      biometricLoginEnabled: _biometricLoginEnabled,
                                      authService: _authService,
                                      onTogglePasswordVisibility: _togglePasswordVisibility,
                                      onLogin: _login,
                                      onBiometricLogin: _authenticateWithBiometrics,
                                      validateUsername: LoginValidators.validateUsername,
                                      validatePassword: LoginValidators.validatePassword,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
