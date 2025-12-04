import 'package:flutter/material.dart';

class ViewProfileScreen extends StatelessWidget {
  static const routeName = '/view_profile';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ver perfil')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Información pública de tu perfil.'))),
    );
  }
}
