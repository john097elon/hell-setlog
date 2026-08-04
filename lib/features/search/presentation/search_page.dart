import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/exercise.dart';
import '../../exercise_db/application/exercise_providers.dart';
import '../../exercise_db/presentation/exercise_detail_page.dart';
import '../../exercise_db/presentation/widgets/exercise_thumbnail.dart';
import '../../profile/presentation/user_profile_page.dart';
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
              prefixIcon: Icon(Icons.search_rounded),
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
                  itemCount: 1,
                  itemBuilder: (context, _) => AppPagePadding(
                    top: AppSpacing.sm,
                    child: AppSection(
                      children: <Widget>[
                        for (final user in users) _UserTile(user: user),
                      ],
                    ),
                  ),
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
    return AppRow(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserProfilePage(userId: user.userId),
        ),
      ),
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.bg,
          shape: BoxShape.circle,
          border: Border.all(color: t.border),
        ),
        child: (avatar ?? '').isEmpty
            ? Text(
                initialOf(user.nickname),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              )
            : Image.network(
                avatar!,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_outline, color: t.faintText),
              ),
      ),
      title: user.nickname,
    );
  }
}

class _ExerciseResults extends ConsumerStatefulWidget {
  const _ExerciseResults({required this.query});

  final String query;

  @override
  ConsumerState<_ExerciseResults> createState() => _ExerciseResultsState();
}

class _ExerciseResultsState extends ConsumerState<_ExerciseResults> {
  String _disciplineKey = '';
  String _muscleGroupKey = '';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final discipline = _disciplineKey.isEmpty
        ? null
        : Discipline.values.byName(_disciplineKey);
    final muscleGroup = _muscleGroupKey.isEmpty
        ? null
        : MuscleGroup.values.byName(_muscleGroupKey);
    final showMuscleFilter =
        discipline == null || discipline == Discipline.strength;
    final results = ref.watch(
      exerciseSearchProvider(
        query: widget.query,
        discipline: discipline,
        muscleGroup: showMuscleFilter ? muscleGroup : null,
      ),
    );
    return Column(
      children: <Widget>[
        AppPagePadding(
          top: AppSpacing.sm,
          child: AppSection(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: DropdownButtonFormField<String>(
                  initialValue: _disciplineKey,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.searchDisciplineFilter,
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.filterAll),
                    ),
                    for (final item in Discipline.values)
                      DropdownMenuItem(
                        value: disciplineKey(item),
                        child: Text(disciplineLabel(item)),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _disciplineKey = value ?? '';
                    if (_disciplineKey.isNotEmpty &&
                        _disciplineKey != disciplineKey(Discipline.strength)) {
                      _muscleGroupKey = '';
                    }
                  }),
                ),
              ),
              if (showMuscleFilter)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: DropdownButtonFormField<String>(
                    initialValue: _muscleGroupKey,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.searchMuscleFilter,
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.l10n.filterAll),
                      ),
                      for (final item in MuscleGroup.values)
                        DropdownMenuItem(
                          value: item.name,
                          child: Text(_muscleGroupLabel(context, item)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _muscleGroupKey = value ?? ''),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: results.when(
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
                      itemCount: 1,
                      itemBuilder: (context, _) => AppPagePadding(
                        child: AppSection(
                          children: <Widget>[
                            for (final item in items)
                              AppRow(
                                leading: ExerciseThumbnail(
                                  equipment: item.equipment,
                                  thumbnailUrl: item.thumbnailUrl,
                                  size: 26,
                                ),
                                title: item.nameKo,
                                subtitle: disciplineLabel(item.discipline),
                                trailing: item.isCustom
                                    ? IconButton(
                                        key: ValueKey<String>(
                                          'delete-${item.id}',
                                        ),
                                        tooltip: context
                                            .l10n
                                            .customExerciseDeleteTooltip,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        onPressed: () => _delete(item),
                                      )
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ExerciseDetailPage(exerciseId: item.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              err: (failure) => Center(child: Text(failure.message)),
            ),
          ),
        ),
      ],
    );
  }

  String _muscleGroupLabel(BuildContext context, MuscleGroup group) =>
      switch (group) {
        MuscleGroup.chest => context.l10n.muscleChest,
        MuscleGroup.back => context.l10n.muscleBack,
        MuscleGroup.shoulders => context.l10n.muscleShoulders,
        MuscleGroup.legs => context.l10n.muscleLegs,
        MuscleGroup.arms => context.l10n.muscleArms,
        MuscleGroup.core => context.l10n.muscleCore,
        MuscleGroup.fullBody => context.l10n.muscleFullBody,
        MuscleGroup.other => context.l10n.muscleOther,
      };

  Future<void> _delete(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(
          dialogContext.l10n.customExerciseDeleteConfirm(exercise.nameKo),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.tokens.like,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.customExerciseDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(customExerciseControllerProvider)
        .delete(exercise.id);
    if (!mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}
