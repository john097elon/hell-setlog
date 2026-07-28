import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/features/compose/presentation/capture_flow.dart';
import 'package:heal_setlog/features/feed/presentation/models/feed_post.dart';
import 'package:heal_setlog/features/feed/presentation/models/sample_feed.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_controls.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_post_card.dart';

/// 소셜 홈. 내 파티 피드(기본) ↔ 지역·종목 필터 공개 피드.
class HomePage extends ConsumerStatefulWidget {
  /// 홈 화면을 생성한다.
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
    final posts = _visiblePosts();
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _TopBar(),
            FeedSwitcher(
              scope: _scope,
              onChanged: (s) => setState(() => _scope = s),
            ),
            Expanded(
              // 피드는 길어질 수 있어 지연 빌드(ListView.builder). 0번은 헤더 슬롯.
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 2, bottom: 24),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _scope == FeedScope.party
                        ? const PartyStrip(party: kSampleParty)
                        : PublicFilters(
                            filters: _filters,
                            onPartySelected: (p) => setState(
                              () => _filters = _filters.copyWith(
                                bodyPart: p,
                                clearPart: p == null,
                              ),
                            ),
                          );
                  }
                  final post = posts[index - 1];
                  return FeedPostCard(
                    key: ValueKey<String>(
                      '${post.author.name}-${post.timeLabel}',
                    ),
                    post: post,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FeedPost> _visiblePosts() {
    if (_scope == FeedScope.party) return kPartyFeed;
    final part = _filters.bodyPart;
    if (part == null) return kPublicFeed;
    return kPublicFeed.where((p) => p.bodyPart == part).toList(growable: false);
  }
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
