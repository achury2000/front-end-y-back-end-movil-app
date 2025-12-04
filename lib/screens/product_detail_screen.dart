// **Pantalla**: Detalle del producto.
// Muestra información completa del producto/recorrido, galería, stock y acciones de reserva.
// parte isa
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reviews_provider.dart';
import '../models/review.dart';
import 'login_screen.dart';
import 'reservations_flow_screen.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/product-detail';
  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // variables de cantidad/variante retiradas: reserva ahora se maneja en el flujo de reservas

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return Scaffold(body: Center(child: Text('Producto no especificado')));

    final prodProv = Provider.of<ProductsProvider>(context, listen: false);
    Product? product;
    try {
      product = prodProv.findById(id);
    } catch (e) {
      product = null;
    }

    if (product == null) return Scaffold(body: Center(child: Text('Producto no encontrado')));

    final p = product;

    final favProv = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(p.name), actions: [
        IconButton(
          icon: Icon(favProv.isFavorite(p.id) ? Icons.favorite : Icons.favorite_border, color: favProv.isFavorite(p.id) ? Colors.red : null),
          onPressed: () => favProv.toggle(p.id),
          tooltip: favProv.isFavorite(p.id) ? 'Quitar de favoritos' : 'Agregar a favoritos',
        )
      ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(p.imageUrl, height: 200, fit: BoxFit.cover, width: double.infinity),
              SizedBox(height: 8),
              Text(p.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('COP ${p.price.toStringAsFixed(0)}'),
              SizedBox(height: 12),
              Text(p.description),
              SizedBox(height:12),
              // Detalles adicionales para enriquecer la descripción de la ruta
              Card(
                margin: EdgeInsets.symmetric(vertical:8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Itinerario', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height:6),
                    Text('- Punto de encuentro y registro\n- Recorrido guiado y paradas de interés\n- Actividad principal y tiempo para preguntas\n- Retorno y despedida', style: TextStyle(height:1.4)),
                    SizedBox(height:8),
                    Text('Incluye', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height:6),
                    Wrap(spacing:8, children: [Chip(label: Text('Guía experto')), Chip(label: Text('Seguro básico')), Chip(label: Text('Transporte parcial'))]),
                    SizedBox(height:8),
                    Row(children:[Text('Duración:', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(width:8), Text('3-4 horas')])
                  ]),
                ),
              ),
              SizedBox(height:8),
              // Mostrar control de stock solo a administradores
              Builder(builder: (ctx) {
                final auth = Provider.of<AuthProvider>(ctx, listen: false);
                final role = (auth.user?.role ?? '').toLowerCase();
                if (role != 'admin') return SizedBox.shrink();
                return Card(
                  margin: EdgeInsets.symmetric(vertical:8),
                  child: Padding(padding: EdgeInsets.all(12), child: Row(children:[
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Control de Stock', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height:6), Text('Stock actual: ${p.stock}')])),
                    Column(children:[
                      Text('Umbral'),
                      SizedBox(height:6),
                      ElevatedButton(onPressed: () async {
                        final prov = Provider.of<ProductsProvider>(context, listen: false);
                        final current = prov.reorderLevelFor(p.id);
                        final txtCtrl = TextEditingController(text: current.toString());
                        final confirmed = await showDialog<int?>(context: context, builder: (_)=> AlertDialog(title: Text('Ajustar umbral de reorden'), content: TextField(controller: txtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Umbral')), actions: [TextButton(onPressed: ()=> Navigator.of(context).pop(null), child: Text('Cancelar')), TextButton(onPressed: (){ final v = int.tryParse(txtCtrl.text.trim()) ?? current; Navigator.of(context).pop(v); }, child: Text('Guardar'))]));
                        if (confirmed != null){
                          await prov.setReorderLevel(p.id, confirmed);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Umbral actualizado')));
                        }
                      }, child: Text('Editar'))
                    ])
                  ])),
                );
              }),
              SizedBox(height:8),
              Card(
                margin: EdgeInsets.symmetric(vertical:8),
                child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text('Recomendaciones', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height:6),
                  Text('Traer calzado cómodo, bloqueador solar, agua y cámara. Respetar indicaciones del guía.')
                ])),
              ),

              SizedBox(height:8),
              // Pequeña galería
              Text('Galería', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height:8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (ctx,i){
                    final base = p.imageUrl;
                    final url = base.replaceFirst('/400/300', '/400/300?img=${i+1}');
                    return Padding(padding: EdgeInsets.only(right:8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url.isNotEmpty?url:'https://picsum.photos/120/80?random=${i}', width:120, height:80, fit: BoxFit.cover)));
                  }
                ),
              ),

              SizedBox(height:12),
              Card(
                margin: EdgeInsets.symmetric(vertical:8),
                child: Padding(padding: EdgeInsets.all(12), child: Consumer<ReviewsProvider>(
                  builder: (ctx, reviewsProv, _) {
                    final targetType = p.category.toLowerCase().contains('finca') ? 'finca' : 'service';
                    final items = reviewsProv.search(targetId: p.id, targetType: targetType);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                        Text('Comentarios', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextButton.icon(onPressed: ()=> _showAddCommentDialog(ctx, p, targetType), icon: Icon(Icons.add_comment), label: Text('Comentar'))
                      ]),
                      SizedBox(height:8),
                      if (items.isEmpty) Center(child: Padding(padding: EdgeInsets.symmetric(vertical:12), child: Text('Sé el primero en comentar esta experiencia'))),
                      ...items.map((r) => Column(children:[
                        ListTile(leading: CircleAvatar(child: Text((r.authorId.isNotEmpty? r.authorId[0].toUpperCase() : 'A'))), title: Text(r.authorId), subtitle: Text(r.comment ?? ''), trailing: Text(r.rating.toString())),
                        Divider()
                      ])).toList(),
                    ]);
                  }
                )),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.white,
        child: Row(children: [
          Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final redirect = ReservationsFlowScreen.routeName;
              final redirectArgs = {'id': p.id, 'qty': 1};
              final allowed = ['cliente', 'client'];
              if (auth.isAuthenticated) {
                final role = (auth.user?.role ?? '').toLowerCase();
                if (allowed.contains(role)) {
                  Navigator.of(context).pushNamed(redirect, arguments: redirectArgs);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acceso restringido: se necesita una cuenta de cliente.')));
                }
              } else {
                Navigator.of(context).pushNamed(LoginScreen.routeName, arguments: {'redirect': redirect, 'redirectArgs': redirectArgs, 'allowedRoles': allowed});
              }
            },
            child: Text('Reservar'),
          )
        ]),
      )),
    );
  }

  void _showAddCommentDialog(BuildContext context, Product p, String targetType) {
    final _ctrl = TextEditingController();
    final _nameCtrl = TextEditingController();
    int _rating = 5;

    showDialog(context: context, builder: (ctx){
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAuth = auth.isAuthenticated;
      return StatefulBuilder(builder: (ctx, setState){
        return AlertDialog(
          title: Text('Agregar comentario'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!isAuth) TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Tu nombre (opcional)')),
            TextField(controller: _ctrl, decoration: InputDecoration(labelText: 'Comentario'), maxLines: 4),
            SizedBox(height:8),
            Row(children:[Text('Puntuación:'), SizedBox(width:8), DropdownButton<int>(value: _rating, items: [5,4,3,2,1].map((n)=> DropdownMenuItem(child: Text('$n'), value: n)).toList(), onChanged: (v)=> setState(()=> _rating = v ?? _rating))])
          ])),
          actions: [
            TextButton(onPressed: ()=> Navigator.of(ctx).pop(), child: Text('Cancelar')),
            ElevatedButton(onPressed: () async {
              final authorId = isAuth ? (auth.user?.id ?? 'anon') : (_nameCtrl.text.trim().isEmpty ? 'anon' : _nameCtrl.text.trim());
              final id = Uuid().v4();
              final r = Review(id: id, targetId: p.id, targetType: targetType, authorId: authorId, rating: _rating, comment: _ctrl.text.trim());
              try{
                await Provider.of<ReviewsProvider>(context, listen: false).addReview(r);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comentario agregado')));
              }catch(e){
                showDialog(context: context, builder: (_)=> AlertDialog(title: Text('Error'), content: Text(e.toString()), actions: [TextButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('Cerrar'))]));
              }
            }, child: Text('Enviar'))
          ],
        );
      });
    });
  }
}
