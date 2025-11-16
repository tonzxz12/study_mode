import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/styles.dart';
import '../../core/theme/theme_colors.dart';
import 'register_screen.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final showPassword = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final authService = AuthService();

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      
      try {
        final result = await authService.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (result.success && context.mounted) {
          // Navigate to main app
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spaceLG,
              vertical: AppStyles.spaceMD,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppStyles.spaceLG),
                  // Sigma Branding
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        // Sigma Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                            boxShadow: context.shadowLG,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                            child: Image.asset(
                              'assets/images/sigma.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.flash_on_rounded,
                                  size: 40,
                                  color: context.primary,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.spaceMD),
                        // Sigma Title
                        Text(
                          'Sigma',
                          style: AppStyles.screenTitle.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: context.primary,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spaceXS),
                        Text(
                          'Unlock your potential. Master your studies.',
                          style: AppStyles.bodyMedium.copyWith(
                            color: context.mutedForeground,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceLG),
                  
                  // Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                      border: Border.all(
                        color: context.border.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.foreground,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        labelStyle: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                        ),
                        hintStyle: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                        ),
                        prefixIcon: Icon(
                          Icons.email_rounded,
                          size: 20,
                          color: context.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceMD,
                          vertical: AppStyles.spaceSM,
                        ),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceMD),
                  
                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                      border: Border.all(
                        color: context.border.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword.value,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.foreground,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        labelStyle: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                        ),
                        hintStyle: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: context.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: context.mutedForeground,
                          ),
                          onPressed: () => showPassword.value = !showPassword.value,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceMD,
                          vertical: AppStyles.spaceSM,
                        ),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceLG),
                  
                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primary,
                          context.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: context.primaryForeground,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        ),
                      ),
                      child: isLoading.value
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: context.primaryForeground,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  size: 20,
                                  color: context.primaryForeground,
                                ),
                                const SizedBox(width: AppStyles.spaceXS),
                                Text(
                                  'Sign In',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: context.primaryForeground,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceMD),
                  
                  // Forgot Password Button
                  TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog(context, authService);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceLG,
                        vertical: AppStyles.spaceMD,
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceLG),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: context.border.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
                        child: Text(
                          'OR',
                          style: AppStyles.bodyMedium.copyWith(
                            color: context.mutedForeground,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: context.border.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spaceLG),
                  
                  // Register Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.primary.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                      color: context.primary.withOpacity(0.05),
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            color: context.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppStyles.spaceXS),
                          Text(
                            'Create New Account',
                            style: AppStyles.bodyMedium.copyWith(
                              color: context.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceLG),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showForgotPasswordDialog(BuildContext context, AuthService authService) {
  final emailController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
      ),
      title: Text(
        'Reset Password',
        style: AppStyles.sectionHeader.copyWith(
          color: context.foreground,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your email address to receive a password reset link.',
            style: AppStyles.bodyMedium.copyWith(
              color: context.mutedForeground,
            ),
          ),
          const SizedBox(height: AppStyles.spaceLG),
          Container(
            decoration: BoxDecoration(
              color: context.background,
              borderRadius: BorderRadius.circular(AppStyles.radiusLG),
              border: Border.all(
                color: context.border.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppStyles.bodyMedium.copyWith(color: context.foreground),
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                labelStyle: AppStyles.bodyMedium.copyWith(color: context.mutedForeground),
                hintStyle: AppStyles.bodyMedium.copyWith(color: context.mutedForeground),
                prefixIcon: Icon(Icons.email_rounded, color: context.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppStyles.spaceLG),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spaceLG,
              vertical: AppStyles.spaceMD,
            ),
          ),
          child: Text(
            'Cancel',
            style: AppStyles.bodyMedium.copyWith(
              color: context.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (emailController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your email')),
              );
              return;
            }
            
            try {
              await authService.resetPassword(email: emailController.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary,
            foregroundColor: context.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLG),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spaceLG,
              vertical: AppStyles.spaceMD,
            ),
          ),
          child: Text(
            'Send Reset Email',
            style: AppStyles.bodyMedium.copyWith(
              color: context.primaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}