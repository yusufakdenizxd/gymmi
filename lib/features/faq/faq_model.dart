class FAQ {
  final String id;
  final String question;
  final String answer;
  final int order;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory FAQ.fromMap(Map<String, dynamic> map, String id) {
    return FAQ(
      id: id,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}
