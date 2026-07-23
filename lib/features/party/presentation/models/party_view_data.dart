/// 화면 목업에만 사용하는 파티 표시 데이터다.
class PartyViewData {
  /// 화면 목업 데이터를 생성한다.
  const PartyViewData({
    required this.name,
    required this.members,
    required this.missionCompleted,
    required this.missionTarget,
    required this.focus,
  });

  final String name;
  final int members;
  final int missionCompleted;
  final int missionTarget;
  final String focus;
}

/// 화면 목업에만 사용하는 친구 표시 데이터다.
class PartyFriendViewData {
  /// 화면 목업 친구 데이터를 생성한다.
  const PartyFriendViewData({required this.name, required this.level});

  final String name;
  final int level;
}

/// 화면 목업에만 사용하는 채팅 표시 데이터다.
class PartyChatViewData {
  /// 화면 목업 채팅 데이터를 생성한다.
  const PartyChatViewData({
    required this.author,
    required this.message,
    required this.isMine,
  });

  final String author;
  final String message;
  final bool isMine;
}

/// 파티 화면에서만 사용하는 정적 목업 데이터다.
const PartyViewData myPartyViewData = PartyViewData(
  name: '번개 레이스',
  members: 3,
  missionCompleted: 3,
  missionTarget: 4,
  focus: '전신',
);

/// 탐색 목록의 화면 전용 목업 데이터다.
const List<PartyViewData> explorePartyViewData = <PartyViewData>[
  PartyViewData(
    name: '번개 레이스',
    members: 3,
    missionCompleted: 3,
    missionTarget: 4,
    focus: '전신',
  ),
  PartyViewData(
    name: '등 운동 연구소',
    members: 4,
    missionCompleted: 2,
    missionTarget: 5,
    focus: '등',
  ),
  PartyViewData(
    name: '하체 성장단',
    members: 5,
    missionCompleted: 4,
    missionTarget: 6,
    focus: '하체',
  ),
];

/// 친구 초대 행의 화면 전용 목업 데이터다.
const List<PartyFriendViewData> partyFriendViewData = <PartyFriendViewData>[
  PartyFriendViewData(name: '민수', level: 12),
  PartyFriendViewData(name: '서연', level: 8),
  PartyFriendViewData(name: '지훈', level: 15),
];

/// 초기 채팅 버블의 화면 전용 목업 데이터다.
const List<PartyChatViewData> initialPartyChatViewData = <PartyChatViewData>[
  PartyChatViewData(author: '민수', message: '오늘도 운동 완료!', isMine: false),
  PartyChatViewData(author: '나', message: '저도 곧 시작해요.', isMine: true),
  PartyChatViewData(author: '서연', message: '미션 하나 남았어요!', isMine: false),
];
