import 'package:flutter/material.dart';

class AdvisorDashboardScreen extends StatelessWidget {
  static const routeName = '/advisor';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel Asesor')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Bienvenido, Asesor', style: TextStyle(fontSize:18, fontWeight: FontWeight.w700)),
          SizedBox(height:12),
          Card(child: ListTile(title: Text('Mis Reservas'), subtitle: Text('Ver y gestionar reservas asignadas'))),
          SizedBox(height:8),
          Card(child: ListTile(title: Text('Clientes Asignados'), subtitle: Text('Ver clientes y su historial'))),
          SizedBox(height:8),
          Card(child: ListTile(title: Text('Reportes Rápidos'), subtitle: Text('Resumen de ventas y KPI'))),
        ])
      ),
    );
  }
}
