import 'package:flutter/material.dart';

import 'feed_post.dart';

// ponytail: 백엔드(P3+) 전까지 프론트 확인용 하드코딩 샘플. 리포지토리 붙으면 교체.

const PartySummary kSampleParty = PartySummary(
  name: '번개 레이더스',
  doneCount: 3,
  totalCount: 4,
  todayXp: 720,
  missionPercent: 75,
);

const List<FeedPost> kPartyFeed = <FeedPost>[
  FeedPost(
    author: FeedAuthor(name: '준혁', level: 31, isLive: true),
    timeLabel: '방금',
    bodyPart: '가슴',
    media: FeedMedia(
      kind: FeedMediaKind.video,
      gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
      durationLabel: '0:18',
    ),
    summary: WorkoutSummary(
      metrics: <({String label, String value})>[
        (label: '볼륨', value: '6,240 kg'),
        (label: '시간', value: '52분'),
      ],
      prLabel: '인클라인 PR',
      xp: 240,
    ),
    likes: 128,
    comments: 9,
    caption: '오늘 벤치 80 찍음 🔥',
  ),
  FeedPost(
    author: FeedAuthor(name: '지민', level: 22),
    timeLabel: '12분 전',
    bodyPart: '하체',
    media: FeedMedia(
      kind: FeedMediaKind.photo,
      gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
      count: 3,
    ),
    summary: WorkoutSummary(
      metrics: <({String label, String value})>[
        (label: '스쿼트', value: '100 kg×3'),
      ],
      prLabel: '스쿼트 PR',
    ),
    likes: 84,
    comments: 3,
    caption: '하체day 계단이 무섭다 😵',
  ),
];

const List<FeedPost> kPublicFeed = <FeedPost>[
  FeedPost(
    author: FeedAuthor(name: '헬창왕', level: 58),
    timeLabel: '방금',
    bodyPart: '가슴',
    location: '강남',
    showFollow: true,
    media: FeedMedia(
      kind: FeedMediaKind.video,
      gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
      durationLabel: '0:32',
    ),
    summary: WorkoutSummary(
      metrics: <({String label, String value})>[
        (label: '벤치', value: '120 kg×3'),
        (label: '볼륨', value: '9,800 kg'),
      ],
      prLabel: '벤치 PR',
    ),
    likes: 842,
    comments: 41,
    caption: '강남 3대 500 모임 구합니다 💪',
  ),
  FeedPost(
    author: FeedAuthor(name: '수아', level: 27),
    timeLabel: '8분 전',
    bodyPart: '가슴',
    location: '서초',
    showFollow: true,
    media: FeedMedia(
      kind: FeedMediaKind.photo,
      gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
      count: 4,
    ),
    summary: WorkoutSummary(
      metrics: <({String label, String value})>[
        (label: '체스트프레스', value: '50 kg×12'),
      ],
      xp: 180,
    ),
    likes: 219,
    comments: 12,
    caption: '가슴 파티원 모집 중 ~',
  ),
];
