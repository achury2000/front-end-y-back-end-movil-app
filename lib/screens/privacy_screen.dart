import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  static const routeName = '/privacy';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacidad')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Política de privacidad y permisos.'))),
    );
  }
}
