import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 첫 실행에서 앱의 쓰임새를 소개한다. 문구는 `assets/onboarding.json`에서 읽는다.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onDone, super.key});

  /// 마지막 장 또는 건너뛰기로 온보딩이 끝났을 때 호출한다.
  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  List<_Slide> _slides = const <_Slide>[];
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 문구 파일이 없거나 깨져도 앱이 멈추지 않도록 조용히 건너뛴다.
  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/onboarding.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      final slides = decoded
          .whereType<Map<String, dynamic>>()
          .map(_Slide.fromJson)
          .toList(growable: false);
      if (!mounted) return;
      if (slides.isEmpty) {
        widget.onDone();
        return;
      }
      setState(() {
        _slides = slides;
        _loading = false;
      });
    } on Object {
      if (mounted) widget.onDone();
    }
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingDoneKey, true);
    } on Object {
      // 저장 실패는 무시한다. 다음 실행에 다시 보여줄 뿐이다.
    }
    if (mounted) widget.onDone();
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (_loading) {
      return Scaffold(backgroundColor: t.bg, body: const SizedBox.shrink());
    }
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('건너뛰기', style: TextStyle(color: t.mutedText)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _SlideView(slide: _slides[index]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? _slides[_index].cta : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 완료 여부를 저장하는 키.
const String onboardingDoneKey = 'onboarding_done';

class _Slide {
  const _Slide({required this.title, required this.body, required this.cta});

  factory _Slide.fromJson(Map<String, dynamic> json) => _Slide(
    title: (json['title'] as String?) ?? '',
    body: (json['body'] as String?) ?? '',
    cta: (json['cta'] as String?) ?? '시작하기',
  );

  final String title;
  final String body;
  final String cta;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.text,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/branding/app_icon_fg.png',
              width: 44,
              height: 44,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.local_fire_department, color: t.onBrand),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.2,
              color: t.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: TextStyle(fontSize: 15, height: 1.5, color: t.mutedText),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Duration(milliseconds: reduce ? 0 : 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? t.text : t.borderStrong,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
