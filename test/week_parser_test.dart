import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/parsers/week_parser.dart';

void main() {
  group('parseWeeks', () {
    test(
      'parses continuous range',
      () => expect(parseWeeks('1-16周'), List.generate(16, (i) => i + 1)),
    );
    test(
      'parses odd weeks with English parentheses',
      () => expect(parseWeeks('1-16周(单)'), [1, 3, 5, 7, 9, 11, 13, 15]),
    );
    test(
      'parses even weeks with Chinese parentheses',
      () => expect(parseWeeks('2-16周（双）'), [2, 4, 6, 8, 10, 12, 14, 16]),
    );
    test(
      'parses separated ranges',
      () => expect(parseWeeks('1-7,9-16周'), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
      ]),
    );
    test(
      'parses discrete weeks',
      () => expect(parseWeeks('1,3,5,7周'), [1, 3, 5, 7]),
    );
    test(
      'deduplicates and sorts',
      () => expect(parseWeeks('3,1,1-2周'), [1, 2, 3]),
    );
    test(
      'rejects malformed input',
      () =>
          expect(() => parseWeeks('1--4周'), throwsA(isA<WeekParseException>())),
    );
    test(
      'rejects reversed range',
      () =>
          expect(() => parseWeeks('8-2周'), throwsA(isA<WeekParseException>())),
    );
  });

  test(
    'formatWeeks compresses consecutive weeks',
    () => expect(formatWeeks([1, 2, 3, 5, 7, 8]), '1-3,5,7-8周'),
  );
}
