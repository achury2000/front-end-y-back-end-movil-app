import 'package:flutter/material.dart';

class ClientHomeScreen extends StatelessWidget {
  static const routeName = '/client/home';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inicio Cliente')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Bienvenido', style: TextStyle(fontSize:18, fontWeight: FontWeight.w700)),
          SizedBox(height:12),
          Card(child: ListTile(title: Text('Mis Reservas'), subtitle: Text('Ver reservas activas y su historial'))),
          SizedBox(height:8),
          Card(child: ListTile(title: Text('Ofertas para ti'), subtitle: Text('Campañas y promociones'))),
          SizedBox(height:8),
          Card(child: ListTile(title: Text('Mi Perfil'), subtitle: Text('Actualizar información personal'))),
        ])
      ),
    );
  }
}
