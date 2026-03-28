class StringUtils {
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  static String? nullIfEmpty(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String kebabToTitle(String text) {
    return text.split('-').map(capitalize).join(' ');
  }
}
