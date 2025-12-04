import 'package:flutter/material.dart';

class FindCohostScreen extends StatelessWidget {
  static const routeName = '/find_cohost';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Encuentra un coanfitrión')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Explora posibles coanfitriones.'))),
    );
  }
}
