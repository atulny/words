import 'package:http/http.dart' as http;
import 'dart:convert';

class Word {
  final String text;
  int order;

  Word({required this.text, required this.order});

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      text: json['word'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': text,
      'order': order,
    };
  }
}

class WordService {
  static final WordService _instance = WordService._internal();
  factory WordService() => _instance;
  WordService._internal();
  static const String baseUrl = 'http://localhost:8080'; // Use this for iOS simulator

  List<Word> _words = [];

  List<Word> get words => _words;

  Future<void> fetchWords(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/words'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _words = data.map((item) => Word.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch words');
    }
  }

  Future<void> addWord(String word, String token) async {
    final newOrder = _words.isEmpty ? 0 : _words.last.order + 1;
    final response = await http.post(
      Uri.parse('$baseUrl/words'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'word': word, 'order': newOrder}),
    );

    if (response.statusCode == 200) {
      _words.add(Word(text: word, order: newOrder));
    } else {
      throw Exception('Failed to add word');
    }
  }

  Future<void> reorderWords(String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/words/reorder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_words.map((word) => word.toJson()).toList()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder words');
    }
  }
}

