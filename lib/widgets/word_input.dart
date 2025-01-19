import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:word_memorizer/services/auth_service.dart';
import 'package:word_memorizer/services/word_service.dart';

class WordInput extends StatefulWidget {
  const WordInput({super.key});

  @override
  _WordInputState createState() => _WordInputState();
}
Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () { },
  );
 // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("My title"),
    content: const Text("This is my message."),
    actions: [
      okButton,
    ],
  );
class _WordInputState extends State<WordInput> {
  final TextEditingController _wordController = TextEditingController();
  final WordService _wordService = WordService();
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
    if (_wordController.text.isNotEmpty) {
      final token = Provider.of<AuthService>(context, listen: false).token;
        print('onError: $token');
      if (token != null) {
        showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    });
        await _wordService.addWord(_wordController.text, token);
        _wordController.clear();
        setState(() {});

      }
    }
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

