import 'package:flutter/material.dart';

/// 피드 탭. 내 파티 활동(기본) / 공개 탐색.
enum FeedScope { party, public }

/// 미디어 종류. 영상은 재생 버튼·길이·LIVE 배지를 붙인다.
enum FeedMediaKind { photo, video }

/// 게시자.
@immutable
class FeedAuthor {
  const FeedAuthor({
    required this.name,
    required this.level,
    this.isLive = false,
  });

  final String name;
  final int level;
  final bool isLive;
}

/// 미디어(사진/영상) 한 건. 실제 백엔드 연동 전까지 톤 플레이스홀더로 렌더한다.
@immutable
class FeedMedia {
  const FeedMedia({
    required this.kind,
    required this.gradient,
    this.durationLabel,
    this.count = 1,
  });

  final FeedMediaKind kind;
  final List<Color> gradient;

  /// 영상 길이 표기(`0:18`). 사진이면 null.
  final String? durationLabel;

  /// 캐러셀 장수(1이면 인디케이터 숨김).
  final int count;
}

/// 미디어 하단에 붙는 운동 요약. 지표 1~3개 + PR/XP 강조.
@immutable
class WorkoutSummary {
  const WorkoutSummary({required this.metrics, this.prLabel, this.xp});

  final List<({String label, String value})> metrics;
  final String? prLabel;
  final int? xp;
}

/// 피드 게시물.
@immutable
class FeedPost {
  const FeedPost({
    required this.author,
    required this.timeLabel,
    required this.bodyPart,
    required this.media,
    required this.summary,
    required this.likes,
    required this.comments,
    required this.caption,
    this.location,
    this.showFollow = false,
  });

  final FeedAuthor author;
  final String timeLabel;
  final String bodyPart;
  final FeedMedia media;
  final WorkoutSummary summary;
  final int likes;
  final int comments;
  final String caption;

  /// 공개 피드 지역 배지(`강남`). 파티 피드면 null.
  final String? location;

  /// 공개 피드에서 팔로우 버튼 노출.
  final bool showFollow;
}

/// 내 파티 요약 스트립 데이터.
@immutable
class PartySummary {
  const PartySummary({
    required this.name,
    required this.doneCount,
    required this.totalCount,
    required this.todayXp,
    required this.missionPercent,
  });

  final String name;
  final int doneCount;
  final int totalCount;
  final int todayXp;
  final int missionPercent;
}

/// 공개 피드 필터. 지역·종목.
@immutable
class FeedFilters {
  const FeedFilters({this.region = '강남구', this.bodyPart});

  final String region;

  /// 선택된 종목(가슴/등/하체…). null이면 전체.
  final String? bodyPart;

  FeedFilters copyWith({
    String? region,
    String? bodyPart,
    bool clearPart = false,
  }) => FeedFilters(
    region: region ?? this.region,
    bodyPart: clearPart ? null : (bodyPart ?? this.bodyPart),
  );
}

const List<String> kBodyParts = <String>['가슴', '등', '하체', '어깨', '팔', '3대측정'];
