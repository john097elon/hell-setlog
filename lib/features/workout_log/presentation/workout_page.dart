import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 레거시 운동 시작·진행·완료 흐름을 로컬 상태로 재현하는 목업 화면이다.
class WorkoutPage extends StatefulWidget {
  /// 운동 기록 목업 화면을 생성한다.
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<int> _completedSets = <int>[];
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  _WorkoutPhase _phase = _WorkoutPhase.ready;
  String _recordType = 'start';

  void _start() {
    setState(() => _phase = _WorkoutPhase.active);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _completeSet() {
    setState(() => _completedSets.add(_completedSets.length + 1));
  }

  void _end() {
    _timer?.cancel();
    setState(() => _phase = _WorkoutPhase.complete);
  }

  void _restart() {
    setState(() {
      _completedSets.clear();
      _elapsed = Duration.zero;
      _recordType = 'start';
      _phase = _WorkoutPhase.ready;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _WorkoutPhase.ready => _ReadyWorkout(onStart: _start),
      _WorkoutPhase.active => _ActiveWorkout(
        elapsed: _elapsed,
        completedSets: _completedSets,
        recordType: _recordType,
        onRecordTypeChanged: (String value) =>
            setState(() => _recordType = value),
        onCompleteSet: _completeSet,
        onEnd: _end,
      ),
      _WorkoutPhase.complete => _CompleteWorkout(
        elapsed: _elapsed,
        sets: _completedSets.length,
        onRestart: _restart,
      ),
    };
  }
}

enum _WorkoutPhase { ready, active, complete }

class _ReadyWorkout extends StatelessWidget {
  const _ReadyWorkout({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(copy.todayWorkout)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.todayWorkout,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.todayWorkoutDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: copy.memoOptional,
                      hintText: copy.memoHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(copy.startWorkout),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWorkout extends StatelessWidget {
  const _ActiveWorkout({
    required this.elapsed,
    required this.completedSets,
    required this.recordType,
    required this.onRecordTypeChanged,
    required this.onCompleteSet,
    required this.onEnd,
  });

  final Duration elapsed;
  final List<int> completedSets;
  final String recordType;
  final ValueChanged<String> onRecordTypeChanged;
  final VoidCallback onCompleteSet;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(copy.workoutInProgress)),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(copy.workoutInProgress),
                  const SizedBox(height: 4),
                  Text(
                    _formatElapsed(elapsed),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text('${copy.completedSets} ${completedSets.length}'),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'start',
                        label: Text(copy.recordTypeStart),
                      ),
                      ButtonSegment<String>(
                        value: 'middle',
                        label: Text(copy.recordTypeMiddle),
                      ),
                      ButtonSegment<String>(
                        value: 'end',
                        label: Text(copy.recordTypeEnd),
                      ),
                    ],
                    selected: <String>{recordType},
                    onSelectionChanged: (Set<String> value) =>
                        onRecordTypeChanged(value.first),
                  ),
                ],
              ),
            ),
            Expanded(
              child: completedSets.isEmpty
                  ? Center(child: Text(copy.todayWorkoutDescription))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: completedSets.length,
                      itemBuilder: (BuildContext context, int index) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(copy.setItem(completedSets[index])),
                          subtitle: Text(copy.sampleSetDetails),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onCompleteSet,
                    icon: const Icon(Icons.add_task_rounded),
                    label: Text(copy.completeSet),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(copy.photoMockNotice)),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(copy.photo),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onEnd,
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(copy.endWorkout),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteWorkout extends StatelessWidget {
  const _CompleteWorkout({
    required this.elapsed,
    required this.sets,
    required this.onRestart,
  });

  final Duration elapsed;
  final int sets;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      copy.workoutComplete,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy.potentialAccumulated,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _Summary(
                          label: copy.totalTime,
                          value: _formatElapsed(elapsed),
                        ),
                        _Summary(label: copy.setLogs, value: '$sets'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onRestart,
                      child: Text(copy.startNewWorkout),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(copy.goHome),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _formatElapsed(Duration elapsed) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(elapsed.inHours)}:${twoDigits(elapsed.inMinutes.remainder(60))}:${twoDigits(elapsed.inSeconds.remainder(60))}';
}
