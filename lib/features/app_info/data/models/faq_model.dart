import 'package:clean_boilerplate/features/app_info/domain/entities/faq_entity.dart';

/// Data-layer DTO for an `/api/v1/app/faqs` item.
class FaqModel {
  const FaqModel({required this.id, required this.question, required this.answer});

  factory FaqModel.fromJson(Map<String, dynamic> json) => FaqModel(id: '${json['id']}', question: json['question'] as String? ?? '', answer: json['answer'] as String? ?? '');

  final String id;
  final String question;
  final String answer;

  FaqEntity toEntity() => FaqEntity(id: id, question: question, answer: answer);
}
