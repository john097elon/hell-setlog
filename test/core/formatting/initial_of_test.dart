import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';

void main() {
  test('닉네임이 비어도 아바타 첫 글자가 던지지 않는다', () {
    // 빈 닉네임 프로필이 하나라도 섞이면 목록 전체가 죽던 자리.
    expect(initialOf(''), '?');
    expect(initialOf(null), '?');
    expect(initialOf('   '), '?');
    expect(initialOf('john'), 'j');
    expect(initialOf(' 김헬스'), '김');
    expect(initialOf('👍좋아요'), '👍');
  });
}
