import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/party_providers.dart';

const _regions = <String>['강남구', '서초구', '송파구', '마포구', '성동구', '분당', '수원', '기타'];
const _focuses = <String>['3대측정', '다이어트', '벌크업', '홈트', '러닝', '크로스핏', '자세교정'];

/// 파티를 만드는 하단 시트를 연다.
Future<void> showPartyCreateSheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PartyCreateSheet(),
    );

class _PartyCreateSheet extends ConsumerStatefulWidget {
  const _PartyCreateSheet();

  @override
  ConsumerState<_PartyCreateSheet> createState() => _PartyCreateSheetState();
}

class _PartyCreateSheetState extends ConsumerState<_PartyCreateSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String? _region;
  String? _focus;
  double _maxMembers = 8;
  bool _isPublic = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파티 이름을 2자 이상 입력해 주세요.')));
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(partyRepositoryProvider)
        .createParty(
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          region: _region,
          focus: _focus,
          maxMembers: _maxMembers.round(),
          isPublic: _isPublic,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (party) {
        ref.invalidate(myPartiesProvider);
        Navigator.pop(context);
        final code = party.joinCode;
        if (!_isPublic && (code ?? '').isNotEmpty) {
          _showCode(context, code!);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('파티를 만들었습니다.')));
        }
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  void _showCode(BuildContext context, String code) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('참여 코드'),
        content: Text('$code\n\n이 코드를 공유하면 파티에 참여할 수 있습니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('복사'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '파티 만들기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: t.text,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '파티 이름'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: '소개(선택)'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChipRow(
                label: '지역',
                options: _regions,
                selected: _region,
                onSelected: (value) => setState(() => _region = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChipRow(
                label: '종목',
                options: _focuses,
                selected: _focus,
                onSelected: (value) => setState(() => _focus = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Text(
                    '정원 ${_maxMembers.round()}명',
                    style: TextStyle(
                      color: t.text,
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _maxMembers,
                      min: 2,
                      max: 20,
                      divisions: 18,
                      onChanged: (value) => setState(() => _maxMembers = value),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                title: const Text('공개 파티'),
                subtitle: Text(
                  _isPublic ? '탐색에서 누구나 참여할 수 있습니다.' : '참여 코드를 아는 사람만 들어옵니다.',
                  style: TextStyle(color: t.mutedText),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('만들기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.mutedText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (value) => onSelected(value ? option : null),
              ),
          ],
        ),
      ],
    );
  }
}
