import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/features/compose/presentation/capture_flow.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/feed/presentation/models/feed_post.dart';
import 'package:heal_setlog/features/feed/presentation/models/post_feed_mapper.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_controls.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_post_card.dart';
import 'package:heal_setlog/core/supabase/supabase_init.dart';
import 'package:heal_setlog/features/notifications/application/notification_providers.dart';
import 'package:heal_setlog/features/party/application/party_providers.dart';

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
                  ? const _PartyFeed()
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

/// 내가 속한 첫 파티의 기록을 보여준다. 파티가 없으면 참여를 안내한다.
class _PartyFeed extends ConsumerWidget {
  const _PartyFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties = ref.watch(myPartiesProvider);
    final party = parties.valueOrNull?.firstOrNull;
    if (parties.isLoading) return const FeedListSkeleton();
    if (party == null) {
      // 예전엔 샘플 파티와 가짜 게시물을 보여줘 실제 활동처럼 보였다.
      return const AppEmptyState(
        icon: Icons.groups_outlined,
        title: '아직 파티가 없습니다',
        message: '파티에 참여하면 파티원의 기록이 여기에 모입니다.',
      );
    }
    return ref
        .watch(partyFeedProvider(party.id))
        .when(
          loading: () => const FeedListSkeleton(),
          error: (_, _) => const _FeedError(),
          data: (posts) {
            final header = PartyStrip(
              party: PartySummary(
                name: party.name,
                doneCount: posts.length,
                totalCount: party.memberCount,
                todayXp: 0,
                missionPercent: 0,
              ),
            );
            if (posts.isEmpty) {
              return Column(
                children: <Widget>[
                  header,
                  const Expanded(
                    child: AppEmptyState(
                      icon: Icons.groups_outlined,
                      title: '아직 파티원의 기록이 없습니다',
                      message: '첫 기록을 남겨 파티원들에게 알려보세요.',
                    ),
                  ),
                ],
              );
            }
            return _FeedList(
              posts: posts
                  .map(
                    (post) => feedPostFromPost(
                      post,
                      currentUserId: ref
                          .watch(supabaseClientProvider)
                          ?.auth
                          .currentUser
                          ?.id,
                    ),
                  )
                  .toList(growable: false),
              header: header,
            );
          },
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
              const Expanded(child: FeedListSkeleton()),
            ],
          ),
          data: (posts) {
            final me = ref.watch(supabaseClientProvider)?.auth.currentUser?.id;
            final feedPosts = posts
                .map((post) => feedPostFromPost(post, currentUserId: me))
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
          error: (_, _) => Column(
            children: <Widget>[
              header,
              const Expanded(child: _FeedError()),
            ],
          ),
        );
  }
}

/// 조회 실패를 빈 목록이나 샘플로 감추지 않는다.
class _FeedError extends StatelessWidget {
  const _FeedError();

  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.wifi_off_rounded,
    title: '피드를 불러오지 못했습니다',
    message: '연결을 확인한 뒤 아래로 당겨 다시 시도해 주세요.',
  );
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
        key: ValueKey<String>(
          post.postId ?? '${post.author.name}-${post.timeLabel}-$index',
        ),
        post: post,
      );
    },
  );
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
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
            onPressed: () => context.push('/search'),
            icon: Icon(Icons.search_rounded, color: t.text, size: 24),
          ),
          IconButton(
            tooltip: '게시물 만들기',
            onPressed: () => openCaptureFlow(context),
            icon: Icon(Icons.add_box_outlined, color: t.text, size: 24),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(Icons.notifications_none_rounded, color: t.text, size: 24),
                if (unread > 0)
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
            ),
          ),
        ],
      ),
    );
  }
}
