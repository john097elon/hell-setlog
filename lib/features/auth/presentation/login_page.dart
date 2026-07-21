import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 서버 연결 없이 로그인 화면을 표시하는 목업 페이지다.
class LoginPage extends StatefulWidget {
  /// 로그인 페이지를 생성한다.
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 42,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          copy.appName,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.loginIntro,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: copy.email),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(labelText: copy.password),
                          validator: _required,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(copy.loginButton),
                        ),
                        const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}

String? _required(String? value) => value?.trim().isEmpty ?? true ? '' : null;
