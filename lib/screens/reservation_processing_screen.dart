import 'package:flutter/material.dart';

class ReservationProcessingScreen extends StatelessWidget {
  final Future<String> reservationFuture;
  final String productName;

  const ReservationProcessingScreen({Key? key, required this.reservationFuture, required this.productName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Procesando reserva'), leading: Container()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<String>(
            future: reservationFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height:12), Text('Creando tu reserva para "$productName"...')]);
              }
              if (snap.hasError) {
                return Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error, size:48, color:Colors.red), SizedBox(height:12), Text('Error creando la reserva'), SizedBox(height:12), ElevatedButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('Volver'))]);
              }
              final id = snap.data ?? '';
              return Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size:56, color: Colors.green), SizedBox(height:12), Text('Reserva creada', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)), SizedBox(height:8), Text('ID: $id'), SizedBox(height:18), ElevatedButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('Listo'))]);
            },
          ),
        ),
      ),
    );
  }
}
