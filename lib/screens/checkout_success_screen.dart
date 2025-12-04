import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  static const routeName = '/checkout/success';
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] ?? '-';
    final total = args['total'] ?? 0.0;
    final items = (args['items'] as List<dynamic>?) ?? [];
    final payment = args['paymentMethod'] ?? '-';

    String _buildReceiptText(){
      final buf = StringBuffer();
      buf.writeln('Recibo de compra\n');
      buf.writeln('Pedido: $id');
      buf.writeln('Fecha: ${DateTime.now().toIso8601String()}');
      buf.writeln('Método de pago: $payment\n');
      buf.writeln('Items:');
      for (final it in items) {
        final name = it['productName'] ?? it['name'] ?? '-';
        final qty = it['quantity'] ?? 1;
        final up = it['unitPrice'] ?? 0;
        buf.writeln('- $name x$qty @ COP ${up.toString()}');
      }
      buf.writeln('\nTotal: COP ${total.toString()}\n');
      buf.writeln('Gracias por su compra.');
      return buf.toString();
    }

    final receiptText = _buildReceiptText();

    return Scaffold(
      appBar: AppBar(title: Text('Compra realizada')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 72),
            SizedBox(height:12),
            Text('¡Tu pedido ha sido creado!', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
            SizedBox(height:8),
            Text('Número de pedido: $id', style: TextStyle(fontSize:16)),
            SizedBox(height:6),
            Text('Total: COP ${total.toString()}', style: TextStyle(fontSize:16, fontWeight: FontWeight.w600)),
            SizedBox(height:12),
            ElevatedButton(onPressed: (){ Navigator.of(context).push(MaterialPageRoute(builder: (_)=> _ReceiptView(receipt: receiptText))); }, child: Text('Ver recibo')),
            SizedBox(height:8),
            ElevatedButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: receiptText)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recibo copiado al portapapeles'))); }, child: Text('Copiar recibo')),
            SizedBox(height:12),
            Text('Puedes ver tus órdenes en la sección Mis Compras.', style: TextStyle(color: Colors.grey[700])),
            Spacer(),
            TextButton(onPressed: ()=> Navigator.of(context).pushReplacementNamed('/purchases'), child: Text('Ir a Mis Compras'))
          ],
        ),
      ),
    );
  }
}

class _ReceiptView extends StatelessWidget {
  final String receipt;
  const _ReceiptView({required this.receipt});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recibo')),
      body: Padding(padding: EdgeInsets.all(12), child: SingleChildScrollView(child: SelectableText(receipt))),
    );
  }
}
