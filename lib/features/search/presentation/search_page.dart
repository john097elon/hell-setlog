import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../exercise_db/application/exercise_providers.dart';
import '../../exercise_db/presentation/exercise_detail_page.dart';
import '../../exercise_db/presentation/widgets/exercise_thumbnail.dart';
import '../application/search_providers.dart';

/// 사용자와 운동 종목을 한 화면에서 찾는다.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 타이핑 중 요청이 몰리지 않도록 300ms 뒤에만 반영한다.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: '닉네임 또는 종목 검색',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '사용자'),
              Tab(text: '종목'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _UserResults(query: _query),
            _ExerciseResults(query: _query),
          ],
        ),
      ),
    );
  }
}

class _UserResults extends ConsumerWidget {
  const _UserResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    if (query.isEmpty) {
      return const AppEmptyState(
        icon: Icons.person_search_outlined,
        title: '닉네임을 입력해 주세요',
        message: '함께 운동할 사람을 찾아보세요.',
      );
    }
    return ref
        .watch(userSearchProvider(query))
        .when(
          loading: () => const AppLoading(),
          error: (_, _) => Center(
            child: Text('검색에 실패했습니다.', style: TextStyle(color: t.mutedText)),
          ),
          data: (users) => users.isEmpty
              ? const AppEmptyState(
                  icon: Icons.person_off_outlined,
                  title: '검색 결과가 없습니다',
                  message: '다른 닉네임으로 찾아보세요.',
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) =>
                      _UserTile(user: users[index]),
                ),
        );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final SearchedUser user;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final avatar = user.avatarUrl;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.bg,
          shape: BoxShape.circle,
          border: Border.all(color: t.border),
        ),
        child: (avatar ?? '').isEmpty
            ? Text(
                user.nickname.isEmpty ? '?' : user.nickname.characters.first,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              )
            : Image.network(
                avatar!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_outline, color: t.faintText),
              ),
      ),
      title: Text(user.nickname),
    );
  }
}

class _ExerciseResults extends ConsumerWidget {
  const _ExerciseResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ref
        .watch(exerciseSearchProvider(query: query))
        .when(
          loading: () => const AppLoading(),
          error: (_, _) => Center(
            child: Text('검색에 실패했습니다.', style: TextStyle(color: t.mutedText)),
          ),
          data: (result) => result.when(
            ok: (items) => items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: '종목을 찾지 못했습니다',
                    message: '다른 이름으로 검색해 보세요.',
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: ExerciseThumbnail(
                          equipment: item.equipment,
                          thumbnailUrl: item.thumbnailUrl,
                          size: 46,
                        ),
                        title: Text(item.nameKo),
                        subtitle: Text(equipmentLabelKo(item.equipment)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ExerciseDetailPage(exerciseId: item.id),
                          ),
                        ),
                      );
                    },
                  ),
            err: (failure) => Center(child: Text(failure.message)),
          ),
        );
  }
}
