import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/config/app_env.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/data/repositories/supabase_sync_repository.dart';
import 'package:heal_setlog/features/auth/application/auth_error_message.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';

/// 이메일과 비밀번호로 로그인한다.
class LoginPage extends ConsumerStatefulWidget {
  /// 로그인 페이지를 생성한다.
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    if (!isSupabaseConfigured) {
      context.go('/home');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      _pullInBackground();
      context.go('/home');
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(signInErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pullInBackground() {
    ref.read(syncRepositoryProvider).pullAll().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'HealSetLog',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: t.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy.loginIntro,
                      style: TextStyle(fontSize: 14, color: t.mutedText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: copy.email),
                      controller: _emailController,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: copy.password),
                      controller: _passwordController,
                      validator: _passwordValidator,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(copy.loginButton),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text('${copy.noAccount} ${copy.register}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '이메일을 입력해 주세요.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return '올바른 이메일 형식이 아닙니다.';
  }
  return null;
}

String? _passwordValidator(String? value) =>
    (value?.length ?? 0) < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null;
