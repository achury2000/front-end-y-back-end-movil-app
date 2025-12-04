import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/auth_provider.dart';

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final couponCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Carrito')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: ListView.builder(itemCount: cart.items.length, itemBuilder: (ctx,i){
              final c = cart.items[i];
              return ListTile(
                title: Text(c.product.name),
                subtitle: Text('x${c.quantity} • COP ${c.product.price.toStringAsFixed(0)}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.remove), onPressed: ()=>cart.updateQuantity(c.product.id, c.quantity-1, variant: c.selectedVariant)),
                  Text('${c.quantity}'),
                  IconButton(icon: Icon(Icons.add), onPressed: ()=>cart.updateQuantity(c.product.id, c.quantity+1, variant: c.selectedVariant)),
                  IconButton(icon: Icon(Icons.delete), onPressed: ()=>cart.removeProduct(c.product.id, variant: c.selectedVariant)),
                ]),
              );
            })),
            Divider(),
            Row(children: [Expanded(child: TextField(controller: couponCtrl, decoration: InputDecoration(labelText: 'Cupón'))), SizedBox(width:8), ElevatedButton(onPressed: (){ final ok = cart.applyCoupon(couponCtrl.text.trim()); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok? 'Cupón aplicado' : 'Cupón inválido'))); }, child: Text('Aplicar'))]),
            SizedBox(height:8),
            Text('Subtotal: COP ${cart.subtotal.toStringAsFixed(0)}'),
            Text('Descuento: COP ${cart.discount.toStringAsFixed(0)}'),
            Text('Envío: COP ${cart.shipping.toStringAsFixed(0)}'),
            Text('Total: COP ${cart.total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (!auth.isAuthenticated) {
                        final go = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Inicio de sesión requerido'),
                            content: Text('Debes iniciar sesión para completar la compra.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Ir a inicio')),
                            ],
                          ),
                        );
                        if (go == true) Navigator.of(context).pushNamed('/login');
                        return;
                      }
                      Navigator.of(context).pushNamed('/checkout');
                    },
              child: Text('Pagar'))
          ],
        ),
      ),
    );
  }
}
