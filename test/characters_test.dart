import 'package:call_aaya/characters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every caller has a unique id and something to say', () {
    final ids = callers.map((c) => c.id).toSet();
    expect(ids.length, callers.length);
    for (final c in callers) {
      expect(c.lines, isNotEmpty);
    }
  });

  test('unknown id falls back to the first caller', () {
    expect(callerById('nobody').id, callers.first.id);
  });
}
