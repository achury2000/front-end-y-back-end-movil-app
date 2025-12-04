import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  static const routeName = '/legal';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Legal')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Información legal y términos de servicio.'))),
    );
  }
}
