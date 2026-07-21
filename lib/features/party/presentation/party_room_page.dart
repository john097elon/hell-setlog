import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

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
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            copy.samplePartyName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(copy.samplePartyDescription),
          const SizedBox(height: 24),
          Text(copy.members, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
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
          const SizedBox(height: 24),
          Text(copy.activity, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _FeedCard(
            icon: Icons.person_add_alt_1_rounded,
            message: copy.feedMemberJoined,
          ),
          const SizedBox(height: 10),
          _FeedCard(
            icon: Icons.play_circle_fill_rounded,
            message: copy.feedWorkoutStarted,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.emoji_events_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(copy.feedWorkoutDone)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _reactions += 1),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(copy.reactionCount(_reactions)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/workout'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(copy.startWorkout),
          ),
          const SizedBox(height: 12),
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
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(message),
      ),
    );
  }
}
