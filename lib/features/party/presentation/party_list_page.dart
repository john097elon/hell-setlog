import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 레거시 내 파티와 파티 생성·가입 흐름을 표시하는 목업 화면이다.
class PartyListPage extends StatefulWidget {
  /// 파티 목록 목업 화면을 생성한다.
  const PartyListPage({super.key});

  @override
  State<PartyListPage> createState() => _PartyListPageState();
}

class _PartyListPageState extends State<PartyListPage> {
  _PartyFormMode _mode = _PartyFormMode.none;

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _mode = _PartyFormMode.none);
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(copy.myParties)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            copy.partySubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => setState(() => _mode = _PartyFormMode.create),
                icon: const Icon(Icons.add_rounded),
                label: Text(copy.createParty),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _mode = _PartyFormMode.join),
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(copy.joinParty),
              ),
              OutlinedButton.icon(
                onPressed: () => _showFeedback(copy.randomPartyDescription),
                icon: const Icon(Icons.casino_outlined),
                label: Text(copy.randomParty),
              ),
            ],
          ),
          if (_mode != _PartyFormMode.none) ...<Widget>[
            const SizedBox(height: 16),
            _PartyForm(
              mode: _mode,
              onCancel: () => setState(() => _mode = _PartyFormMode.none),
              onSubmit: () => _showFeedback(copy.mockOnlyNotice),
            ),
          ],
          const SizedBox(height: 28),
          Text(copy.myParties, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PartyCard(
            name: copy.samplePartyName,
            description: copy.samplePartyDescription,
            members: copy.memberCount,
            onTap: () => context.go('/party/room'),
          ),
          const SizedBox(height: 12),
          _PartyCard(
            name: copy.samplePartyNameSecond,
            description: copy.samplePartyDescriptionSecond,
            members: copy.memberCountSecond,
            onTap: () => context.go('/party/room'),
          ),
          const SizedBox(height: 28),
          Text(
            copy.randomPartyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(copy.randomPartyDescription),
          const SizedBox(height: 12),
          _PartyCard(
            name: copy.samplePartyNameSecond,
            description: copy.randomPartyDescription,
            members: copy.memberCount,
            onTap: () => context.go('/party/room'),
          ),
        ],
      ),
    );
  }
}

enum _PartyFormMode { none, create, join }

class _PartyForm extends StatelessWidget {
  const _PartyForm({
    required this.mode,
    required this.onCancel,
    required this.onSubmit,
  });

  final _PartyFormMode mode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final bool isCreate = mode == _PartyFormMode.create;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                labelText: isCreate ? copy.partyName : copy.inviteCode,
                hintText: isCreate ? copy.partyNameHint : copy.inviteCodeHint,
              ),
            ),
            if (isCreate) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: copy.partyDescription,
                  hintText: copy.partyDescriptionHint,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text(copy.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSubmit,
                    child: Text(isCreate ? copy.create : copy.join),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.name,
    required this.description,
    required this.members,
    required this.onTap,
  });

  final String name;
  final String description;
  final String members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.groups_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(members, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              TextButton(onPressed: onTap, child: Text(copy.openParty)),
            ],
          ),
        ),
      ),
    );
  }
}
