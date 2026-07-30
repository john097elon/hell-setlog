import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';

final _faqProvider = FutureProvider<List<_Faq>>((ref) async {
  try {
    final decoded =
        jsonDecode(await rootBundle.loadString('assets/help_faq.json'))
            as List<Object?>;
    return decoded
        .map((item) => _Faq.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  } on Object {
    return const <_Faq>[];
  }
});

class HelpPage extends ConsumerWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqs = ref.watch(_faqProvider);
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('도움말')),
      body: faqs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('도움말을 불러오지 못했습니다')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('도움말을 준비 중입니다'));
          }
          final groups = <String, List<_Faq>>{};
          for (final item in items) {
            groups.putIfAbsent(item.category, () => <_Faq>[]).add(item);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              for (final entry in groups.entries) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final faq in entry.value)
                        ExpansionTile(
                          title: Text(faq.question),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq.answer,
                                style: TextStyle(color: t.mutedText),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Faq {
  const _Faq({
    required this.category,
    required this.question,
    required this.answer,
  });

  factory _Faq.fromJson(Map<String, Object?> json) => _Faq(
    category: json['category'] as String,
    question: json['q'] as String,
    answer: json['a'] as String,
  );

  final String category;
  final String question;
  final String answer;
}
