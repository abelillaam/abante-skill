enum PracticeLanguage {
  python,
  javascript,
  java,
  cpp,
  dart;

  String get label {
    switch (this) {
      case PracticeLanguage.python:
        return 'Python';
      case PracticeLanguage.javascript:
        return 'JavaScript';
      case PracticeLanguage.java:
        return 'Java';
      case PracticeLanguage.cpp:
        return 'C++';
      case PracticeLanguage.dart:
        return 'Dart';
    }
  }

  String get fileName {
    switch (this) {
      case PracticeLanguage.python:
        return 'sandbox.py';
      case PracticeLanguage.javascript:
        return 'sandbox.js';
      case PracticeLanguage.java:
        return 'Sandbox.java';
      case PracticeLanguage.cpp:
        return 'sandbox.cpp';
      case PracticeLanguage.dart:
        return 'sandbox.dart';
    }
  }

  String get starterCode {
    switch (this) {
      case PracticeLanguage.python:
        return '# Sandbox — experiment freely\n\nprint("Hello, world!")\n';
      case PracticeLanguage.javascript:
        return '// Sandbox — experiment freely\n\nconsole.log("Hello, world!");\n';
      case PracticeLanguage.java:
        return '// Sandbox — experiment freely\n\n'
            'public class Sandbox {\n'
            '    public static void main(String[] args) {\n'
            '        System.out.println("Hello, world!");\n'
            '    }\n'
            '}\n';
      case PracticeLanguage.cpp:
        return '// Sandbox — experiment freely\n\n'
            '#include <iostream>\n\n'
            'int main() {\n'
            '    std::cout << "Hello, world!" << std::endl;\n'
            '    return 0;\n'
            '}\n';
      case PracticeLanguage.dart:
        return '// Sandbox — experiment freely\n\n'
            'void main() {\n'
            '  print("Hello, world!");\n'
            '}\n';
    }
  }
}
