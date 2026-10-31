
import 'dart:convert';
import 'package:flutter/services.dart';

class TextbookDatabase {
  static List<dynamic> textbooks = [];
  static List<dynamic> classes = [];

  static Future<void> load() async {
    final data = await rootBundle.loadString(
      'assets/textbooks.json',
    );

    final json = jsonDecode(data);

    textbooks = json['textbooks'] ?? [];
    classes = json['classes'] ?? [];
  }

  static List<dynamic> search({
    int? schoolClass,
    String? subject,
    String? author,
    int? year,
    String? exerciseNumber,
  }) {
    return textbooks.where((book) {
      if (schoolClass != null &&
          book['class'] != schoolClass) {
        return false;
      }

      if (subject != null &&
          subject.isNotEmpty &&
          book['subject'] != subject) {
        return false;
      }

      if (year != null && book['year'] != year) {
        return false;
      }

      if (author != null &&
          author.isNotEmpty) {
        final authors = (book['authors'] ?? [])
            .join(' ')
            .toString()
            .toLowerCase();

        if (!authors.contains(author.toLowerCase())) {
          return false;
        }
      }

      if (exerciseNumber != null &&
          exerciseNumber.isNotEmpty) {
        final exercises = book['exercises'] ?? [];

        return exercises.any(
          (exercise) =>
              exercise['number'].toString() ==
              exerciseNumber,
        );
      }

      return true;
    }).toList();
  }
}
