import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
  static const routeName = '/account_settings';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración de la cuenta')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aquí puedes ajustar la configuración de tu cuenta.'))),
    );
  }
}
