import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../state/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? intendedRole;
  const LoginScreen({super.key, this.intendedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.intendedRole == 'admin') {
      _emailController.text = 'admin@mysumber.my';
    } else if (widget.intendedRole == 'worker') {
      _emailController.text = 'worker@mysumber.my';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<RoleState>();
    await auth.login(_emailController.text.trim(), _passwordController.text);
  }

  String _roleLabel() {
    switch (widget.intendedRole) {
      case 'admin':
        return 'Admin';
      case 'worker':
        return 'Worker';
      default:
        return 'Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = rolePrimary(widget.intendedRole);
    final isCustomer = widget.intendedRole == 'user' ||
        widget.intendedRole == null ||
        widget.intendedRole == 'customer';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text(
          'Sign in as ${_roleLabel()}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        systemOverlayStyle: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'mySumber',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_roleLabel()} sign in',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Consumer<RoleState>(
                builder: (context, auth, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      if (auth.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.criticalSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.critical, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.critical,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: auth.clearError,
                                  child: const Icon(Icons.close,
                                      color: AppColors.critical, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: auth.isLoading ? null : _login,
                        icon: auth.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(auth.isLoading ? 'Signing in…' : 'Sign In'),
                      ),
                      if (isCustomer) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(
                                      onBack: () => Navigator.pop(context),
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                                textStyle:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
