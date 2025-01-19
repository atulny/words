import 'package:flutter/material.dart';
import 'package:word_memorizer/services/auth_service.dart';
import 'package:word_memorizer/services/word_service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class WordInput extends StatefulWidget {
  @override
  State<WordInput> createState() => _WordInputState();
}

class _WordInputState extends State<WordInput> {
  final TextEditingController _wordController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listenForSpeech() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (errorNotification) => print('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _wordController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _addWord() async {
     final wordService = Provider.of<WordService>(context, listen: false);
    final token = Provider.of<AuthService>(context, listen: false).token;

    if (token != null && _wordController.text.isNotEmpty) {
      try {
        await wordService.addWord(_wordController.text, token);
        _wordController.clear(); // Clear the input field after adding the word
        _showSnackBar('Word added successfully!');
      } catch (e) {
        _showSnackBar('Failed to add word. Please try again.');
      }
    }
    // if (_wordController.text.isNotEmpty) {
    //   if (token != null) {
    //     await Provider.of<WordService>(context, listen: false).addWord(_wordController.text, token);
    //     _wordController.clear();
    //     _showSnackBar('Word added successfully!');

    //   }
    // }
  }
void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                hintText: 'Enter a word or phrase',
              ),
              onSubmitted: (value) => _addWord(), // Handle Enter key press

            ),
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _listenForSpeech,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWord,
          ),
        ],
      ),
    );
  }
}

