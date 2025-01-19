import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:word_memorizer/screens/login_screen.dart';
import 'package:word_memorizer/services/auth_service.dart';
import 'package:word_memorizer/widgets/word_input.dart';
import 'package:word_memorizer/widgets/word_list.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Memorizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: WordList()),
          WordInput(),
        ],
      ),
    );
  }
}

