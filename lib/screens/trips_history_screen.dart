import 'package:flutter/material.dart';

class TripsHistoryScreen extends StatelessWidget {
  static const routeName = '/trips_history';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Viajes anteriores')),
      body: Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Lista de viajes previos del usuario.'))),
    );
  }
}
