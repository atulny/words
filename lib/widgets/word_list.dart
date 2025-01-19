import 'package:flutter/material.dart';
import 'package:word_memorizer/services/auth_service.dart';
import 'package:word_memorizer/services/word_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class WordList extends StatefulWidget {
  @override
  _WordListState createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _fetchWords();
  }

  Future<void> _fetchWords() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token != null) {
      await Provider.of<WordService>(context, listen: false).fetchWords(token);
    }
  }
  Future<void> _deleteWord(String wordId) async {
      final wordService = Provider.of<WordService>(context, listen: false);
      final token = Provider.of<AuthService>(context, listen: false).token;

      if (token != null) {
        await wordService.deleteWord(wordId, token);
        _fetchWords(); // Refresh the list after deletion
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
    final wordService = Provider.of<WordService>(context, listen: false);
    final token = Provider.of<AuthService>(context, listen: false).token;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Word item = wordService.words.removeAt(oldIndex);
      wordService.words.insert(newIndex, item);

      // Update order values
      for (int i = 0; i < wordService.words.length; i++) {
        wordService.words[i].order = i;
      }
    });

    if (token != null) {
      await wordService.reorderWords(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WordService>(
      builder: (context, wordService, child) {
        return ReorderableListView.builder(
          itemCount: wordService.words.length,
          onReorder: _reorderWords,
          itemBuilder: (context, index) {
            final word = wordService.words[index];
            return ListTile(
              key: ValueKey(word.text),
              title: Text(word.text),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () => _speakWord(word.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteWord(word.id), // Add delete button
                  ),
                  IconButton(
                    icon: Icon(Icons.language),
                    onPressed: () => _openGooglePronunciation(word.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.alarm),
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
      },
    );
  }
}

