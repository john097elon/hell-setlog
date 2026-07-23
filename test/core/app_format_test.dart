import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';

void main() {
  test('formatInt inserts thousands separators', () {
    expect(formatInt(0), '0');
    expect(formatInt(999), '999');
    expect(formatInt(12400), '12,400');
    expect(formatInt(1200000), '1,200,000');
    expect(formatInt(-5000), '-5,000');
  });

  test('formatWeight drops trailing zero and keeps one decimal', () {
    expect(formatWeight(60), '60');
    expect(formatWeight(62.5), '62.5');
    expect(formatWeight(12400), '12,400');
  });

  test('formatCompactNumber abbreviates K and M', () {
    expect(formatCompactNumber(500), '500');
    expect(formatCompactNumber(12400), '12.4K');
    expect(formatCompactNumber(1200000), '1.2M');
  });
}
