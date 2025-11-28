import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  static const routeName = '/register';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Crear cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Text('Esta pantalla es un placeholder. Implementa tu flujo de registro aquí.', textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('Volver'))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
