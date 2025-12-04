import 'package:flutter/material.dart';

class RecommendHostScreen extends StatelessWidget {
  static const routeName = '/recommend_host';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recomienda a un anfitrión')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Formulario para recomendar anfitriones.'))),
    );
  }
}
