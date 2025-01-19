import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:word_memorizer/services/auth_service.dart';
import 'package:word_memorizer/services/word_service.dart';

class WordList extends StatefulWidget {
  const WordList({super.key});

  @override
  _WordListState createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late WordService _wordService;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _wordService = WordService();
    _flutterTts = FlutterTts();
    _fetchWords();
  }

  Future<void> _fetchWords() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token != null) {
      await _wordService.fetchWords(token);
      setState(() {});
    }
  }

  void _speakWord(String word) async {
    await _flutterTts.speak(word);
  }

  void _openGooglePronunciation(String word) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(word)}+pronunciation');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _reorderWords(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Word item = _wordService.words.removeAt(oldIndex);
      _wordService.words.insert(newIndex, item);

      // Update order values
      for (int i = 0; i < _wordService.words.length; i++) {
        _wordService.words[i].order = i;
      }
    });

    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token != null) {
      await _wordService.reorderWords(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: _wordService.words.length,
      onReorder: _reorderWords,
      itemBuilder: (context, index) {
        final word = _wordService.words[index];
        return ListTile(
          key: ValueKey(word.text),
          title: Text(word.text),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speakWord(word.text),
              ),
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => _openGooglePronunciation(word.text),
              ),
              IconButton(
                icon: const Icon(Icons.alarm),
                onPressed: () {
                  // TODO: Implement reminder functionality
                },
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        );
      },
    );
  }
}

