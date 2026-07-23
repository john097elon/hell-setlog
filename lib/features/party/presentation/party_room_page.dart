import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// 멤버와 활동 피드를 보여주는 파티 방 목업 화면이다.
class PartyRoomPage extends StatefulWidget {
  /// 파티 방 목업 화면을 생성한다.
  const PartyRoomPage({super.key});

  @override
  State<PartyRoomPage> createState() => _PartyRoomPageState();
}

class _PartyRoomPageState extends State<PartyRoomPage> {
  int _reactions = 0;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.partyRoom),
        leading: IconButton(
          tooltip: copy.myParties,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/party'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text(
            copy.samplePartyName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(copy.samplePartyDescription),
          const SizedBox(height: AppSpacing.xl),
          Text(copy.members, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              Chip(
                avatar: const CircleAvatar(child: Text('J')),
                label: Text(copy.sampleCurrentUser),
              ),
              Chip(
                avatar: const CircleAvatar(child: Text('M')),
                label: Text(copy.sampleMemberMinsu),
              ),
              Chip(
                avatar: const CircleAvatar(child: Text('S')),
                label: Text(copy.sampleMemberSeoyeon),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(copy.activity, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _FeedCard(
            icon: Icons.person_add_alt_1_rounded,
            message: copy.feedMemberJoined,
          ),
          const SizedBox(height: AppSpacing.md),
          _FeedCard(
            icon: Icons.play_circle_fill_rounded,
            message: copy.feedWorkoutStarted,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.emoji_events_rounded,
                        color: context.tokens.brand,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(copy.feedWorkoutDone)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _reactions += 1),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(copy.reactionCount(_reactions)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.go('/workout'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(copy.startWorkout),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(copy.inviteCopied))),
            icon: const Icon(Icons.send_outlined),
            label: Text(copy.invite),
          ),
          TextButton(
            onPressed: () => context.go('/party'),
            child: Text(copy.leaveParty),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: context.tokens.brand),
        title: Text(message),
      ),
    );
  }
}
