import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 서버 연결 없이 회원가입 흐름을 보여주는 목업 페이지다.
class RegisterPage extends StatefulWidget {
  /// 회원가입 페이지를 생성한다.
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(),
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
                        Text(
                          copy.register,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(copy.registerIntro),
                        const SizedBox(height: 28),
                        TextFormField(
                          decoration: InputDecoration(labelText: copy.nickname),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
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
                          child: Text(copy.registerButton),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text('${copy.hasAccount} ${copy.login}'),
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
