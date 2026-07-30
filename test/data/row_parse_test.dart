import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/remote/row_parse.dart';

void main() {
  test('numeric이 문자열로 와도 실수로 읽는다', () {
    // PostgREST는 정밀도 유지를 위해 numeric을 문자열로 돌려줄 수 있다.
    expect(rowDouble(<String, Object?>{'v': '270.0'}, 'v'), 270.0);
    expect(rowDouble(<String, Object?>{'v': 270}, 'v'), 270.0);
    expect(rowDouble(<String, Object?>{'v': null}, 'v'), isNull);
    expect(rowDouble(<String, Object?>{}, 'v'), isNull);
    expect(rowDouble(<String, Object?>{'v': 'abc'}, 'v'), isNull);
  });

  test('정수는 문자열·실수 입력을 모두 견딘다', () {
    expect(rowInt(<String, Object?>{'v': '12'}, 'v'), 12);
    expect(rowInt(<String, Object?>{'v': 12.6}, 'v'), 13);
    expect(rowInt(<String, Object?>{'v': '12.4'}, 'v'), 12);
    expect(rowInt(<String, Object?>{'v': null}, 'v'), isNull);
  });

  test('문자열은 없거나 비어도 안전하다', () {
    expect(rowString(<String, Object?>{'v': null}, 'v'), '');
    expect(rowString(<String, Object?>{}, 'v', fallback: '회원'), '회원');
    expect(rowStringOrNull(<String, Object?>{'v': ''}, 'v'), isNull);
    expect(rowStringOrNull(<String, Object?>{'v': 'a'}, 'v'), 'a');
  });

  test('시각 파싱 실패는 대체값으로 떨어진다', () {
    final fallback = DateTime(2026);
    expect(
      rowDate(<String, Object?>{'v': 'not-a-date'}, 'v', fallback: fallback),
      fallback,
    );
    expect(
      rowDate(<String, Object?>{'v': '2026-07-30T08:56:07Z'}, 'v').year,
      2026,
    );
    expect(rowDateOrNull(<String, Object?>{'v': null}, 'v'), isNull);
  });

  test('조인 결과가 객체든 배열이든 읽는다', () {
    expect(
      rowNested(<String, Object?>{
        'profiles': <String, Object?>{'nickname': 'a'},
      }, 'profiles')?['nickname'],
      'a',
    );
    expect(
      rowNested(<String, Object?>{
        'profiles': <Object?>[
          <String, Object?>{'nickname': 'b'},
        ],
      }, 'profiles')?['nickname'],
      'b',
    );
    expect(rowNested(<String, Object?>{'profiles': null}, 'profiles'), isNull);
  });

  test('목록 응답 형태가 달라도 던지지 않는다', () {
    expect(rowList(null), isEmpty);
    expect(rowList('oops'), isEmpty);
    expect(
      rowList(<Object?>[
        <String, Object?>{'id': '1'},
        'junk',
      ]).length,
      1,
    );
  });
}
