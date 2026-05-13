import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/styles/app_colors.dart';
import 'package:truebpm/utils/global_store.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isBiometricAvailable;
  final bool biometricLoginEnabled;
  final AuthService authService;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLogin;
  final VoidCallback onBiometricLogin;
  final String? Function(String?) validateUsername;
  final String? Function(String?) validatePassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.errorMessage,
    required this.isBiometricAvailable,
    required this.biometricLoginEnabled,
    required this.authService,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
    required this.onBiometricLogin,
    required this.validateUsername,
    required this.validatePassword,
  });

  static const _surfaceColor = Color(0xD90A1A29);
  static const _surfaceBorderColor = Color(0x334895C1);
  static const _inputBorderColor = Color(0x334895C1);
  static const _inputFocusedColor = Color(0xFF76D4FF);
  static const _softTextColor = Color(0xCCFFFFFF);
  static const _mutedTextColor = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    final showBiometric = isBiometricAvailable && biometricLoginEnabled;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: usernameController,
                validator: validateUsername,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: _inputFocusedColor,
                decoration: _inputDecoration(
                  labelText: appStrings.usernameLabel,
                  prefixIcon: Icons.person_outline,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                validator: validatePassword,
                obscureText: obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: _inputFocusedColor,
                decoration: _inputDecoration(
                  labelText: appStrings.passwordLabel,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    splashRadius: 22,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _mutedTextColor,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorMessage(message: errorMessage!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(appStrings.loginButton),
                      ),
                    ),
                  ),
                  if (showBiometric) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: ElevatedButton(
                        onPressed: onBiometricLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: const BorderSide(color: _surfaceBorderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: FutureBuilder<List<BiometricType>>(
                          future: authService.getAvailableBiometrics(),
                          builder: (context, snapshot) {
                            return _BiometricIcon(
                              biometrics:
                                  snapshot.data ?? const <BiometricType>[],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _softTextColor, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _inputFocusedColor,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(prefixIcon, color: _mutedTextColor, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: _inputBorder(_inputBorderColor),
      focusedBorder: _inputBorder(_inputFocusedColor, width: 1.4),
      errorBorder: _inputBorder(const Color(0xFFFF7A7A)),
      focusedErrorBorder: _inputBorder(const Color(0xFFFF7A7A), width: 1.4),
      errorStyle: const TextStyle(color: Color(0xFFFFB3B3), height: 1.25),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A5F).withOpacity(0.14),
        border: Border.all(color: const Color(0xFFFF7A7A).withOpacity(0.42)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFFA3A3), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFD0D0),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricIcon extends StatelessWidget {
  final List<BiometricType> biometrics;

  const _BiometricIcon({required this.biometrics});

  @override
  Widget build(BuildContext context) {
    if (biometrics.any((item) => item == BiometricType.face)) {
      return Image.asset(
        'assets/logos/face-id.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        color: Colors.white,
      );
    }

    if (biometrics.any((item) => item == BiometricType.fingerprint)) {
      return Image.asset(
        'assets/logos/fingerprint.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        color: Colors.white,
      );
    }

    return const Icon(Icons.lock_outline, size: 24);
  }
}
