import 'package:flutter/material.dart';
import 'login_screen.dart';

class LogoutScreen extends StatelessWidget {
  static const routeName = '/logout';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerrar sesión')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children:[
            Text('¿Deseas cerrar sesión?', style: TextStyle(fontSize: 16)),
            SizedBox(height:12),
            ElevatedButton(onPressed: (){
              // In a real app call AuthProvider.logout()
              Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
            }, child: Text('Cerrar sesión'))
          ])
        )
      ),
    );
  }
}
