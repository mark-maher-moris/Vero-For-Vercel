import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Simple syntax highlighter for code display
/// Supports common languages: Dart, JavaScript, TypeScript, Python, JSON, HTML, CSS, etc.
class SyntaxHighlighter extends StatelessWidget {
  final String code;
  final String fileName;
  final double fontSize;

  const SyntaxHighlighter({
    super.key,
    required this.code,
    required this.fileName,
    this.fontSize = 13,
  });

  String get _language {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return 'dart';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'py':
        return 'python';
      case 'json':
        return 'json';
      case 'html':
      case 'htm':
        return 'html';
      case 'css':
        return 'css';
      case 'scss':
      case 'sass':
        return 'scss';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
      case 'markdown':
        return 'markdown';
      case 'sh':
      case 'bash':
        return 'bash';
      case 'java':
        return 'java';
      case 'kt':
        return 'kotlin';
      case 'swift':
        return 'swift';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'php':
        return 'php';
      case 'rb':
        return 'ruby';
      case 'c':
        return 'c';
      case 'cpp':
      case 'cc':
        return 'cpp';
      case 'h':
        return 'c';
      case 'xml':
        return 'xml';
      case 'sql':
        return 'sql';
      default:
        return 'text';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_language == 'text') {
      return SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          color: AppTheme.onSurface,
          height: 1.5,
        ),
      );
    }

    final spans = _highlightCode(code, _language);
    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        height: 1.5,
      ),
    );
  }

  List<TextSpan> _highlightCode(String code, String language) {
    final List<TextSpan> spans = [];
    final patterns = _getPatterns(language);
    
    int position = 0;
    while (position < code.length) {
      bool matched = false;
      
      for (final pattern in patterns) {
        final match = pattern.regex.matchAsPrefix(code, position);
        if (match != null) {
          spans.add(TextSpan(
            text: match.group(0),
            style: pattern.style,
          ));
          position = match.end;
          matched = true;
          break;
        }
      }
      
      if (!matched) {
        // Add as plain text
        spans.add(TextSpan(
          text: code[position],
          style: TextStyle(color: AppTheme.onSurface),
        ));
        position++;
      }
    }
    
    return spans;
  }

  List<_HighlightPattern> _getPatterns(String language) {
    final patterns = <_HighlightPattern>[];
    
    // Comments (highest priority)
    if (language == 'dart' || language == 'javascript' || language == 'typescript' || 
        language == 'java' || language == 'kotlin' || language == 'swift' || 
        language == 'go' || language == 'rust' || language == 'php' || 
        language == 'c' || language == 'cpp') {
      patterns.add(_HighlightPattern(
        RegExp(r'//.*$|/\*.*?\*/', multiLine: true),
        TextStyle(color: const Color(0xFF6A9955), fontStyle: FontStyle.italic),
      ));
    }
    
    if (language == 'python' || language == 'yaml' || language == 'bash') {
      patterns.add(_HighlightPattern(
        RegExp(r'#.*$|//.*$', multiLine: true),
        TextStyle(color: const Color(0xFF6A9955), fontStyle: FontStyle.italic),
      ));
    }
    
    if (language == 'html' || language == 'xml') {
      patterns.add(_HighlightPattern(
        RegExp(r'<!--.*?-->', multiLine: true),
        TextStyle(color: const Color(0xFF6A9955), fontStyle: FontStyle.italic),
      ));
    }
    
    if (language == 'css' || language == 'scss') {
      patterns.add(_HighlightPattern(
        RegExp(r'/\*.*?\*/', multiLine: true),
        TextStyle(color: const Color(0xFF6A9955), fontStyle: FontStyle.italic),
      ));
    }
    
    // Strings (high priority)
    patterns.add(_HighlightPattern(
      RegExp(r'''"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`'''),
      TextStyle(color: const Color(0xFFCE9178)),
    ));
    
    // Numbers
    patterns.add(_HighlightPattern(
      RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
      TextStyle(color: const Color(0xFFB5CEA8)),
    ));
    
    // Keywords
    final keywords = _getKeywords(language);
    if (keywords.isNotEmpty) {
      patterns.add(_HighlightPattern(
        RegExp(r'\b(?:' + keywords.join('|') + r')\b'),
        TextStyle(color: const Color(0xFF569CD6), fontWeight: FontWeight.bold),
      ));
    }
    
    // Types
    final types = _getTypes(language);
    if (types.isNotEmpty) {
      patterns.add(_HighlightPattern(
        RegExp(r'\b(?:' + types.join('|') + r')\b'),
        TextStyle(color: const Color(0xFF4EC9B0)),
      ));
    }
    
    // Functions
    patterns.add(_HighlightPattern(
      RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)(?=\s*\()'),
      TextStyle(color: const Color(0xFFDCDCAA)),
    ));
    
    // HTML/XML tags
    if (language == 'html' || language == 'xml') {
      patterns.add(_HighlightPattern(
        RegExp(r'<[/?]?[a-zA-Z][^>]*>'),
        TextStyle(color: const Color(0xFF569CD6)),
      ));
      patterns.add(_HighlightPattern(
        RegExp(r'\b[a-zA-Z-]+(?==)'),
        TextStyle(color: const Color(0xFF9CDCFE)),
      ));
    }
    
    // JSON keys
    if (language == 'json') {
      patterns.add(_HighlightPattern(
        RegExp(r'"(?:[^"\\]|\\.)*"(?=\s*:)'),
        TextStyle(color: const Color(0xFF9CDCFE)),
      ));
    }
    
    // CSS properties
    if (language == 'css' || language == 'scss') {
      patterns.add(_HighlightPattern(
        RegExp(r'\b[a-z-]+(?=\s*:)'),
        TextStyle(color: const Color(0xFF9CDCFE)),
      ));
      patterns.add(_HighlightPattern(
        RegExp(r'\.[a-zA-Z_][a-zA-Z0-9_-]*'),
        TextStyle(color: const Color(0xFFD7BA7D)),
      ));
      patterns.add(_HighlightPattern(
        RegExp(r'#[a-zA-Z0-9_-]+'),
        TextStyle(color: const Color(0xFF4EC9B0)),
      ));
    }
    
    // Markdown
    if (language == 'markdown') {
      // Headers
      patterns.add(_HighlightPattern(
        RegExp(r'^#{1,6}\s+.*$', multiLine: true),
        TextStyle(color: const Color(0xFF569CD6), fontWeight: FontWeight.bold),
      ));
      // Bold/Italic
      patterns.add(_HighlightPattern(
        RegExp(r'\*\*.*?\*\*|__.*?__|\*.*?\*|_.*?_'),
        TextStyle(color: const Color(0xFFCE9178), fontWeight: FontWeight.bold),
      ));
      // Code blocks
      patterns.add(_HighlightPattern(
        RegExp(r'`[^`]+`|```[\s\S]*?```'),
        TextStyle(color: const Color(0xFFDCDCAA), backgroundColor: const Color(0x1FFFFFFF)),
      ));
      // Links
      patterns.add(_HighlightPattern(
        RegExp(r'\[.*?\]\(.*?\)'),
        TextStyle(color: const Color(0xFF4EC9B0), decoration: TextDecoration.underline),
      ));
    }
    
    return patterns;
  }

  List<String> _getKeywords(String language) {
    switch (language) {
      case 'dart':
        return ['import', 'export', 'class', 'extends', 'implements', 'mixin', 'with', 
                'abstract', 'static', 'final', 'const', 'var', 'void', 'null', 'true', 
                'false', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 
                'continue', 'return', 'try', 'catch', 'finally', 'throw', 'async', 
                'await', 'yield', 'required', 'late', 'factory', 'get', 'set', 'operator', 
                'typedef', 'enum', 'assert', 'in', 'is', 'new', 'this', 'super'];
      case 'javascript':
      case 'typescript':
        return ['import', 'export', 'from', 'class', 'extends', 'implements', 'static', 
                'final', 'const', 'let', 'var', 'void', 'null', 'undefined', 'true', 
                'false', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 
                'continue', 'return', 'try', 'catch', 'finally', 'throw', 'async', 
                'await', 'yield', 'function', 'interface', 'type', 'namespace', 'module',
                'declare', 'abstract', 'readonly', 'private', 'protected', 'public',
                'typeof', 'instanceof', 'in', 'of', 'new', 'this', 'super', 'debugger'];
      case 'python':
        return ['import', 'from', 'as', 'class', 'def', 'lambda', 'return', 'yield', 
                'if', 'elif', 'else', 'for', 'while', 'break', 'continue', 'pass', 
                'try', 'except', 'finally', 'raise', 'with', 'assert', 'del', 'global', 
                'nonlocal', 'True', 'False', 'None', 'and', 'or', 'not', 'in', 'is', 'async', 'await'];
      case 'java':
        return ['import', 'package', 'class', 'interface', 'extends', 'implements', 
                'abstract', 'static', 'final', 'const', 'void', 'null', 'true', 'false', 
                'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue', 
                'return', 'try', 'catch', 'finally', 'throw', 'throws', 'synchronized',
                'volatile', 'transient', 'native', 'strictfp', 'instanceof', 'new', 'this', 'super'];
      case 'go':
        return ['package', 'import', 'func', 'const', 'var', 'type', 'struct', 'interface',
                'map', 'chan', 'go', 'defer', 'return', 'if', 'else', 'for', 'range',
                'switch', 'case', 'default', 'break', 'continue', 'fallthrough', 'goto',
                'select', 'make', 'new', 'append', 'copy', 'delete', 'len', 'cap',
                'true', 'false', 'nil', 'iota'];
      case 'rust':
        return ['use', 'mod', 'pub', 'crate', 'self', 'super', 'fn', 'let', 'mut', 'const',
                'static', 'type', 'struct', 'enum', 'trait', 'impl', 'where', 'move',
                'if', 'else', 'match', 'for', 'while', 'loop', 'return', 'break', 'continue',
                'async', 'await', 'ref', 'Box', 'Result', 'Option', 'Some', 'None', 'Ok', 'Err'];
      default:
        return [];
    }
  }

  List<String> _getTypes(String language) {
    switch (language) {
      case 'dart':
        return ['int', 'double', 'String', 'bool', 'List', 'Map', 'Set', 'Iterable',
                'Future', 'Stream', 'void', 'dynamic', 'Object', 'num', 'Function',
                'Widget', 'BuildContext', 'State', 'StatelessWidget', 'StatefulWidget'];
      case 'javascript':
      case 'typescript':
        return ['number', 'string', 'boolean', 'any', 'unknown', 'never', 'void',
                'object', 'Array', 'Promise', 'Map', 'Set', 'Record', 'Partial',
                'Required', 'Readonly', 'Pick', 'Omit', 'Exclude', 'Extract'];
      case 'python':
        return ['int', 'float', 'str', 'bool', 'list', 'dict', 'tuple', 'set',
                'frozenset', 'bytes', 'bytearray', 'memoryview', 'NoneType', 'object'];
      case 'java':
        return ['int', 'long', 'float', 'double', 'boolean', 'char', 'byte', 'short',
                'String', 'Object', 'Integer', 'Long', 'Float', 'Double', 'Boolean',
                'Character', 'Byte', 'Short', 'ArrayList', 'HashMap', 'HashSet'];
      case 'go':
        return ['int', 'int8', 'int16', 'int32', 'int64', 'uint', 'uint8', 'uint16',
                'uint32', 'uint64', 'float32', 'float64', 'complex64', 'complex128',
                'bool', 'string', 'byte', 'rune', 'error', 'any'];
      case 'rust':
        return ['i8', 'i16', 'i32', 'i64', 'i128', 'isize', 'u8', 'u16', 'u32', 'u64',
                'u128', 'usize', 'f32', 'f64', 'bool', 'char', 'str', 'String', 'Vec',
                'HashMap', 'Option', 'Result'];
      default:
        return [];
    }
  }
}

class _HighlightPattern {
  final RegExp regex;
  final TextStyle style;
  
  _HighlightPattern(this.regex, this.style);
}
