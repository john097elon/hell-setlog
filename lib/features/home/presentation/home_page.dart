import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/features/compose/presentation/capture_flow.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/feed/presentation/models/feed_post.dart';
import 'package:heal_setlog/features/feed/presentation/models/post_feed_mapper.dart';
import 'package:heal_setlog/features/feed/presentation/models/sample_feed.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_controls.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_post_card.dart';

/// Social home. Party data stays mocked until party persistence is available.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FeedScope _scope = FeedScope.party;
  FeedFilters _filters = const FeedFilters();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _TopBar(),
            FeedSwitcher(
              scope: _scope,
              onChanged: (scope) => setState(() => _scope = scope),
            ),
            Expanded(
              child: _scope == FeedScope.party
                  ? const _FeedList(
                      posts: kPartyFeed,
                      header: PartyStrip(party: kSampleParty),
                    )
                  : _PublicFeed(
                      filters: _filters,
                      onPartSelected: (part) => setState(
                        () => _filters = _filters.copyWith(
                          bodyPart: part,
                          clearPart: part == null,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicFeed extends ConsumerWidget {
  const _PublicFeed({required this.filters, required this.onPartSelected});
  final FeedFilters filters;
  final ValueChanged<String?> onPartSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = PublicFilters(
      filters: filters,
      onPartySelected: onPartSelected,
    );
    return ref
        .watch(publicFeedProvider(filters.bodyPart))
        .when(
          loading: () => Column(
            children: <Widget>[
              header,
              const Expanded(child: AppLoading()),
            ],
          ),
          data: (posts) {
            final feedPosts = posts
                .map(feedPostFromPost)
                .toList(growable: false);
            if (feedPosts.isEmpty) {
              return Column(
                children: <Widget>[
                  header,
                  const Expanded(
                    child: AppEmptyState(
                      icon: Icons.photo_outlined,
                      title: '게시물이 없습니다',
                      message: '첫 게시물을 남겨보세요.',
                    ),
                  ),
                ],
              );
            }
            return _FeedList(posts: feedPosts, header: header);
          },
          error: (_, _) => _FeedList(
            posts: _fallbackPosts(filters.bodyPart),
            header: header,
          ),
        );
  }

  List<FeedPost> _fallbackPosts(String? bodyPart) => kPublicFeed
      .where((post) => bodyPart == null || post.bodyPart == bodyPart)
      .toList(growable: false);
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.posts, required this.header});
  final List<FeedPost> posts;
  final Widget header;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(top: 2, bottom: 24),
    itemCount: posts.length + 1,
    itemBuilder: (context, index) {
      if (index == 0) return header;
      final post = posts[index - 1];
      return FeedPostCard(
        key: ValueKey<String>('${post.author.name}-${post.timeLabel}'),
        post: post,
      );
    },
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 2),
      child: Row(
        children: <Widget>[
          Text(
            'HealSetLog',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: t.text,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: '검색',
            onPressed: () {},
            icon: Icon(Icons.search_rounded, color: t.text, size: 24),
          ),
          IconButton(
            tooltip: '게시물 만들기',
            onPressed: () => openCaptureFlow(context),
            icon: Icon(Icons.add_box_outlined, color: t.text, size: 24),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () {},
            icon: _BellWithDot(color: t.text),
          ),
        ],
      ),
    );
  }
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(Icons.notifications_none_rounded, color: color, size: 24),
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: t.like,
              shape: BoxShape.circle,
              border: Border.all(color: t.bg, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
