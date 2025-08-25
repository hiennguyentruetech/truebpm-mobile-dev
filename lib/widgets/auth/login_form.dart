import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truebpm/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Username Field
              TextFormField(
                controller: usernameController,
                validator: validateUsername,
                decoration: InputDecoration(
                  labelText: appStrings.usernameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              
              const SizedBox(height: 20),
              
              // Password Field
              TextFormField(
                controller: passwordController,
                validator: validatePassword,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: appStrings.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
              ),
              
              const SizedBox(height: 12),
              
              // Error Message
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[600], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Login Button Row with Biometric
              Row(
                children: [
                  // Login Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.blue.withOpacity(0.3),
                        ),
                        child: Text(
                          appStrings.loginButton,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Biometric Button (Face ID / Touch ID)
                  if (isBiometricAvailable && biometricLoginEnabled) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: ElevatedButton(
                        onPressed: onBiometricLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.3),
                          padding: EdgeInsets.zero,
                        ),
                        child: FutureBuilder<List<dynamic>>(
                          future: authService.getAvailableBiometrics(),
                          builder: (context, snapshot) {
                            final biometrics = snapshot.data ?? [];
                            IconData icon = Icons.fingerprint;
                            
                            if (biometrics.contains(BiometricType.face)) {
                              icon = Icons.face;
                            } else if (biometrics.contains(BiometricType.fingerprint)) {
                              icon = Icons.fingerprint;
                            }
                            
                            return Icon(icon, size: 24);
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
}
