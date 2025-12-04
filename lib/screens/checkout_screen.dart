import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Tarjeta';
  bool _loading = false;

  Future<void> _confirmPurchase() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final purchasesProv = Provider.of<PurchasesProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);
    try {
      final items = cart.items.map((c) => {
            'productId': c.product.id,
            'productName': c.product.name,
            'quantity': c.quantity,
            'unitPrice': c.product.price,
            'variant': c.selectedVariant
          }).toList();
      final data = {
        'items': items,
        'subtotal': cart.subtotal,
        'shipping': cart.shipping,
        'discount': cart.discount,
        'total': cart.total,
        'paymentMethod': _paymentMethod,
        'status': 'Pendiente',
        'createdAt': DateTime.now().toIso8601String()
      };
      final id = await purchasesProv.addPurchase(data, actor: {'id': auth.user?.id ?? '', 'name': auth.user?.name ?? ''});
      // Success: capture summary before clearing cart
      final receiptItems = List<Map<String, dynamic>>.from(items);
      final total = cart.total;
      cart.clear();
      Navigator.of(context).pushReplacementNamed('/checkout/success', arguments: {
        'id': id,
        'total': total,
        'items': receiptItems,
        'paymentMethod': _paymentMethod,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear la compra')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Resumen de compra')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artículos', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height:8),
            Expanded(
              child: ListView.separated(
                itemCount: cart.items.length,
                separatorBuilder: (_,__)=> Divider(),
                itemBuilder: (ctx,i){
                  final c = cart.items[i];
                  return ListTile(
                    title: Text(c.product.name),
                    subtitle: Text('x${c.quantity} · COP ${c.product.price.toStringAsFixed(0)}'),
                    trailing: Text('COP ${(c.product.price * c.quantity).toStringAsFixed(0)}'),
                  );
                }
              ),
            ),
            Divider(),
            Text('Resumen', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height:6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal'), Text('COP ${cart.subtotal.toStringAsFixed(0)}')]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Descuento'), Text('COP ${cart.discount.toStringAsFixed(0)}')]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Envío'), Text('COP ${cart.shipping.toStringAsFixed(0)}')]),
            SizedBox(height:6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('COP ${cart.total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold))]),
            SizedBox(height:12),
            Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height:8),
            DropdownButton<String>(value: _paymentMethod, items: ['Tarjeta','Efectivo','PSE','Pago en sitio'].map((m)=> DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v)=> setState(()=> _paymentMethod = v ?? _paymentMethod)),
            SizedBox(height:12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmPurchase,
                child: _loading ? SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)) : Text('Confirmar y Pagar')
              ),
            )
          ],
        ),
      ),
    );
  }
}
