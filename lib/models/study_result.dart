class StudyException implements Exception {
  final String message;
  StudyException(this.message);

  @override
  String toString() => message;
}

class StudyStep {
  final String title;
  final String explanation;

  StudyStep({required this.title, required this.explanation});

  factory StudyStep.fromJson(Map<String, dynamic> json) => StudyStep(
    title: (json['title'] ?? '').toString(),
    explanation: (json['explanation'] ?? '').toString(),
  );
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String why;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.why,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    question: (json['question'] ?? '').toString(),
    options: ((json['options'] ?? []) as List)
        .map((e) => e.toString())
        .toList(),
    answerIndex: (json['answer_index'] ?? 0) as int,
    why: (json['why'] ?? '').toString(),
  );
}

class Flashcard {
  final String front;
  final String back;

  Flashcard({required this.front, required this.back});

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    front: (json['front'] ?? '').toString(),
    back: (json['back'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'front': front, 'back': back};
}

class StudyResult {
  final String topic;
  final List<StudyStep> steps;
  final List<QuizQuestion> quiz;
  final List<Flashcard> flashcards;

  StudyResult({
    required this.topic,
    required this.steps,
    required this.quiz,
    required this.flashcards,
  });

  factory StudyResult.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      throw StudyException(json['error'].toString());
    }
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) build) =>
        ((json[key] ?? []) as List)
            .map((e) => build(Map<String, dynamic>.from(e as Map)))
            .toList();

    return StudyResult(
      topic: (json['topic'] ?? 'Study notes').toString(),
      steps: parse('steps', StudyStep.fromJson),
      quiz: parse('quiz', QuizQuestion.fromJson),
      flashcards: parse('flashcards', Flashcard.fromJson),
    );
  }
}
