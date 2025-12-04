import 'package:flutter/material.dart';

class ConnectionsScreen extends StatelessWidget {
  static const routeName = '/connections';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conexiones')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Conexiones y contactos del usuario.'))),
    );
  }
}
