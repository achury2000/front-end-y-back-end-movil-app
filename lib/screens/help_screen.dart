import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  static const routeName = '/help';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Obtén ayuda')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Centro de ayuda y preguntas frecuentes.'))),
    );
  }
}
