import "package:unorm_dart/unorm_dart.dart" as unorm;

import 'code_points/bidirectional_l.dart';
import 'code_points/bidirectional_r_al.dart';
import 'code_points/commonly_mapped_to_nothing.dart';
import 'code_points/non_ASCII_space_characters.dart';
import 'code_points/prohibited_characters.dart';
import 'code_points/unassigned.dart';
import 'saslprep_options.dart';

class Saslprep {
  /// Convert provided string into an array of Unicode Code Points.
  /// Based on https://stackoverflow.com/a/21409165/1556249
  /// and https://www.npmjs.com/package/code-point-at.
  static List<int> toCodePoints(String input) {
    List<int> codePoints = [];
    int size = input.length;

    for (int i = 0; i < size; i += 1) {
      var before = input.codeUnitAt(i);

      if (before >= 0xd800 && before <= 0xdbff && size > i + 1) {
        var next = input.codeUnitAt(i + 1);

        if (next >= 0xdc00 && next <= 0xdfff) {
          codePoints.add((before - 0xd800) * 0x400 + next - 0xdc00 + 0x10000);
          i += 1;
          continue;
        }
      }

      codePoints.add(before);
    }

    return codePoints;
  }

  /// This computes the saslprep algorithm. to allow allow unassigned use the
  /// [options] and set [options.allowUnassigned] to true
  static saslprep(String input, {SaslprepOptions options = null}) {
    if (input.isEmpty) {
      return '';
    }

    // 1. Map
    Iterable<int> mapped_input = toCodePoints(input)
        // 1.1 mapping to space
        .map((character) =>
            (non_ASCII_space_characters.indexOf(character) >= 0 ? 0x20 : character))
        // 1.2 mapping to nothing
        .where((character) => commonly_mapped_to_nothing.indexOf(character) == -1);

    // 2. Normalize
    String normalized_input = unorm.nfkc(String.fromCharCodes(mapped_input));

    List<int> normalized_map = toCodePoints(normalized_input);

    // 3. Prohibit
    bool hasProhibited = normalized_map
        .any((character) => prohibited_characters.indexOf(character) >= 0);

    if (hasProhibited) {
      throw new Exception(
          'Prohibited character, see https://tools.ietf.org/html/rfc4013#section-2.3');
    }

    // Unassigned Code Points
    if (options == null || options.allowUnassigned != true) {
      bool hasUnassigned = normalized_map
          .any((character) => unassigned_code_points.indexOf(character) >= 0);
      if (hasUnassigned) {
        throw new Exception(
            'Unassigned code point, see https://tools.ietf.org/html/rfc4013#section-2.5');
      }
    }

    // 4. check bidi
    bool hasBidiRAL = normalized_map
        .any((character) => bidirectional_r_al.indexOf(character) >= 0);
    bool hasBidiL =
        normalized_map.any((character) => bidirectional_l.indexOf(character) >= 0);

    // 4.1 If a string contains any RandALCat character, the string MUST NOT
    // contain any LCat character.
    if (hasBidiRAL && hasBidiL) {
      throw new Exception(
          'String must not contain RandALCat and LCat at the same time, see https://tools.ietf.org/html/rfc3454#section-6');
    }

    //4.2 If a string contains any RandALCat character, a RandALCat
    //character MUST be the first character of the string, and a
    //RandALCat character MUST be the last character of the string.
    bool isFirstBidiRAL = bidirectional_r_al.indexOf(normalized_input.codeUnitAt(0)) >= 0;
    bool isLastBidiRAL = bidirectional_r_al.indexOf(normalized_input.codeUnitAt(normalized_input.length - 1)) >= 0;

    if (hasBidiRAL && !(isFirstBidiRAL && isLastBidiRAL)) {
      throw new Exception(
          'Bidirectional RandALCat character must be the first and the last character of the string, see https://tools.ietf.org/html/rfc3454#section-6');
    }

    return normalized_input;
  }
}
