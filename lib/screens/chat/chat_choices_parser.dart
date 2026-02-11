/// Парсер для Choice Chips в чаті
/// Розпізнає блок [CHOICES]...[/CHOICES] у відповідях AI
/// Версія: 1.0.0
/// Дата: 10.02.2026

class ChatParsedMessage {
  final String textBefore;
  final List<String> choices;
  final String textAfter;

  ChatParsedMessage({
    required this.textBefore,
    required this.choices,
    required this.textAfter,
  });
}

class ChatChoicesParser {
  static final _choicesRegex = RegExp(
    r'\[CHOICES\](.*?)\[/CHOICES\]',
    dotAll: true,
  );

  /// Чи є choices у тексті
  static bool hasChoices(String text) {
    return _choicesRegex.hasMatch(text);
  }

  /// Парсинг тексту з choices
  static ChatParsedMessage parse(String text) {
    final match = _choicesRegex.firstMatch(text);

    if (match == null) {
      return ChatParsedMessage(
        textBefore: text,
        choices: [],
        textAfter: '',
      );
    }

    final textBefore = text.substring(0, match.start).trim();
    final textAfter = text.substring(match.end).trim();
    final choicesBlock = match.group(1) ?? '';

    // Розбиваємо на рядки, прибираємо нумерацію та пусті рядки
    final choices = choicesBlock
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          // Прибираємо нумерацію: "1. ", "2. ", "- ", "• "
          return line
              .replaceFirst(RegExp(r'^\d+\.\s*'), '')
              .replaceFirst(RegExp(r'^[-•]\s*'), '')
              .trim();
        })
        .where((line) => line.isNotEmpty)
        .toList();

    return ChatParsedMessage(
      textBefore: textBefore,
      choices: choices,
      textAfter: textAfter,
    );
  }
}
