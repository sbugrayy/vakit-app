// Türkçe metin katlama ve görüntüleme adı yardımcıları.

const _foldMap = <String, String>{
  'a': 'A',
  'b': 'B',
  'c': 'C',
  'd': 'D',
  'e': 'E',
  'f': 'F',
  'g': 'G',
  'h': 'H',
  'i': 'I',
  'j': 'J',
  'k': 'K',
  'l': 'L',
  'm': 'M',
  'n': 'N',
  'o': 'O',
  'p': 'P',
  'q': 'Q',
  'r': 'R',
  's': 'S',
  't': 'T',
  'u': 'U',
  'v': 'V',
  'w': 'W',
  'x': 'X',
  'y': 'Y',
  'z': 'Z',
  'ç': 'C',
  'Ç': 'C',
  'ğ': 'G',
  'Ğ': 'G',
  'ı': 'I',
  'I': 'I',
  'İ': 'I',
  'ö': 'O',
  'Ö': 'O',
  'ş': 'S',
  'Ş': 'S',
  'ü': 'U',
  'Ü': 'U',
  'â': 'A',
  'Â': 'A',
  'î': 'I',
  'Î': 'I',
  'û': 'U',
  'Û': 'U',
  'ô': 'O',
  'Ô': 'O',
  'ê': 'E',
  'Ê': 'E',
};

const _turkishUpperMap = <String, String>{
  'a': 'A',
  'b': 'B',
  'c': 'C',
  'd': 'D',
  'e': 'E',
  'f': 'F',
  'g': 'G',
  'h': 'H',
  'i': 'İ',
  'j': 'J',
  'k': 'K',
  'l': 'L',
  'm': 'M',
  'n': 'N',
  'o': 'O',
  'p': 'P',
  'q': 'Q',
  'r': 'R',
  's': 'S',
  't': 'T',
  'u': 'U',
  'v': 'V',
  'w': 'W',
  'x': 'X',
  'y': 'Y',
  'z': 'Z',
  'ç': 'Ç',
  'ğ': 'Ğ',
  'ı': 'I',
  'ö': 'Ö',
  'ş': 'Ş',
  'ü': 'Ü',
  'â': 'Â',
  'î': 'Î',
  'û': 'Û',
  'ô': 'Ô',
  'ê': 'Ê',
};

const _turkishLowerMap = <String, String>{
  'A': 'a',
  'B': 'b',
  'C': 'c',
  'D': 'd',
  'E': 'e',
  'F': 'f',
  'G': 'g',
  'H': 'h',
  'I': 'ı',
  'J': 'j',
  'K': 'k',
  'L': 'l',
  'M': 'm',
  'N': 'n',
  'O': 'o',
  'P': 'p',
  'Q': 'q',
  'R': 'r',
  'S': 's',
  'T': 't',
  'U': 'u',
  'V': 'v',
  'W': 'w',
  'X': 'x',
  'Y': 'y',
  'Z': 'z',
  'Ç': 'ç',
  'Ğ': 'ğ',
  'İ': 'i',
  'Ö': 'ö',
  'Ş': 'ş',
  'Ü': 'ü',
  'Â': 'â',
  'Î': 'î',
  'Û': 'û',
  'Ô': 'ô',
  'Ê': 'ê',
};

String _titleCaseWord(String word) {
  final runes = word.runes.toList();
  final firstChar = String.fromCharCode(runes.first);
  final buffer = StringBuffer(_turkishUpperMap[firstChar] ?? firstChar);

  for (var i = 1; i < runes.length; i++) {
    final char = String.fromCharCode(runes[i]);
    buffer.write(_turkishLowerMap[char] ?? char);
  }
  return buffer.toString();
}

String foldTurkish(String input) {
  final withoutParens = input.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  final cleaned = withoutParens.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  for (final rune in cleaned.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_foldMap[char] ?? char);
  }
  return buffer.toString();
}

String displayName(String diyanetName) {
  final withoutParens = diyanetName.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  final cleaned = withoutParens.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) {
    return '';
  }

  return cleaned.split(' ').map(_titleCaseWord).join(' ');
}
