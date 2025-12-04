// parte isa
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/reservations_provider.dart';
import 'login_screen.dart';

class ReservationsFlowScreen extends StatefulWidget {
  static const routeName = '/reservations/flow';
  @override
  _ReservationsFlowScreenState createState() => _ReservationsFlowScreenState();
}

class _ReservationsFlowScreenState extends State<ReservationsFlowScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  String _payment = 'card';
  DateTime? _startDate;
  DateTime? _endDate;
  int _guests = 1;
  bool _isSaving = false;

  @override
  void dispose(){
    _pc.dispose();
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      final auth = Provider.of<AuthProvider>(context, listen:false);
      // If not authenticated, redirect to login and request return to this flow
      if (!auth.isAuthenticated) {
        final args = ModalRoute.of(context)?.settings.arguments;
        Navigator.of(context).pushNamed(LoginScreen.routeName, arguments: {'redirect': ReservationsFlowScreen.routeName, 'redirectArgs': args, 'allowedRoles': ['cliente','client']});
        return;
      }
      // If authenticated but not a client, deny access
      final role = (auth.user?.role ?? '').toLowerCase();
      if (!(role == 'cliente' || role == 'client')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acceso restringido: solo clientes pueden crear reservas.')));
        Navigator.of(context).pop();
      }
    });
  }

  void _next(){
    if (_page < 2) {
      final target = _page + 1;
      // Schedule navigation to next page asynchronously so the UI can finish current work
      Future.microtask(() async {
        try {
          _pc.jumpToPage(target);
        } catch (_) {
          await _pc.animateToPage(target, duration: Duration(milliseconds: 300), curve: Curves.ease);
        }
      });
      setState(()=> _page = target);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev(){
    if (_page > 0) {
      final target = _page - 1;
      try {
        _pc.jumpToPage(target);
      } catch (_) {
        _pc.previousPage(duration: Duration(milliseconds:300), curve: Curves.ease);
      }
      setState(()=> _page = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String,dynamic>?;
    final productId = args?['id'] as String?;
    final qty = args?['qty'] as int? ?? 1;
    // la variante es opcional; no es necesaria en este flujo actualmente
    final products = Provider.of<ProductsProvider>(context, listen:false);
    final product = productId != null ? products.findById(productId) : null;

    return Scaffold(
      appBar: AppBar(title: Text('Reserva'), leading: BackButton()),
      body: Column(children:[
        Expanded(child: PageView(controller: _pc, physics: NeverScrollableScrollPhysics(), onPageChanged: (i)=> setState(()=> _page = i), children:[
          // Step 1: Review
          Padding(padding: EdgeInsets.all(12), child: ListView(children:[
            Text('Revisa y continúa', style: TextStyle(fontSize:22, fontWeight: FontWeight.w700)),
            SizedBox(height:12),
            Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Row(children:[
                if (product != null) Image.network(product.imageUrl, width:72, height:72, fit: BoxFit.cover),
                SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(product?.name ?? '-', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height:6), Text('x$qty')])),
                Text('COP ${product?.price.toStringAsFixed(0) ?? '0'}')
              ]),
              Divider(),
              ListTile(
                title: Text('Fechas'),
                subtitle: Text(_startDate != null && _endDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} – ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'No seleccionadas'),
                trailing: ElevatedButton(onPressed: () => _pickDateRange(context), child: Text('Cambiar'))
              ),
              ListTile(
                title: Text('Huéspedes'),
                subtitle: Text(_guests == 1 ? '1 adulto' : '$_guests huéspedes'),
                trailing: ElevatedButton(onPressed: () => _pickGuests(context), child: Text('Cambiar'))
              ),
              ListTile(
                title: Text('Precio total'),
                subtitle: Text('COP ${_computeTotal(product, qty).toStringAsFixed(0)}'),
                trailing: TextButton(onPressed: ()=> _showPriceDetails(context, product, qty), child: Text('Detalles'))),
              SizedBox(height:8), Text('Esta reservación no es reembolsable.', style: TextStyle(color: Colors.black54)),
            ])))
          ])),

          // Step 2: Payment methods
          Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Agrega un método de pago', style: TextStyle(fontSize:22, fontWeight: FontWeight.w700)),
            SizedBox(height:12),
            Card(child: Column(children:[
              ListTile(
                leading: Icon(_payment == 'card' ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text('Tarjeta de crédito o débito'),
                subtitle: Row(children:[Image.network('https://upload.wikimedia.org/wikipedia/commons/0/04/Visa.svg', width:24), SizedBox(width:6), Image.network('https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg', width:24)]),
                onTap: () => setState(()=> _payment = 'card'),
              ),
              Divider(height:1),
              ListTile(
                leading: Icon(_payment == 'google' ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text('Google Pay'),
                onTap: () => setState(()=> _payment = 'google'),
              ),
            ])),
            SizedBox(height:8),
            if (_payment == 'card') Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: ()=> _showAddCard(context), child: Text('Agregar tarjeta')))
          ])),

          // Step 3: Confirmation (placeholder)
          Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Resumen final', style: TextStyle(fontSize:22, fontWeight: FontWeight.w700)),
            SizedBox(height:12),
            Expanded(child: Center(child: Text('Presiona Siguiente para confirmar la reserva'))),
          ]))
        ])),

        Container(padding: EdgeInsets.all(12), color: Colors.white, child: Row(children:[
          TextButton(onPressed: _prev, child: Text('Atrás')),
          Spacer(),
          ElevatedButton(onPressed: () async {
            if (_isSaving) return;
            if (_page < 2) {
              // Validation: on first page, ensure dates are selected
              if (_page == 0 && (_startDate == null || _endDate == null)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleccione fechas antes de continuar')));
                return;
              }
              _next();
              return;
            }

            // confirm: create reservation
            // Show spinner and allow a frame to render before heavy work
            setState(()=> _isSaving = true);
            await Future.delayed(Duration(milliseconds: 50));
            try {
              final reservations = Provider.of<ReservationsProvider>(context, listen:false);
              // Build the reservation payload
              final payload = {
                'service': product?.name ?? 'Servicio',
                'date': _startDate != null ? _startDate!.toIso8601String().split('T').first : DateTime.now().toIso8601String().split('T').first,
                'time': '09:00',
                'price': _computeTotal(product, qty),
                'status': 'Activa',
                'guests': _guests
              };

              // Fire-and-forget: don't await persistence to avoid any chance of UI blocking.
              try {
                reservations.addReservation(payload).then((id) {
                  // Optionally show a later confirmation when persistence finished
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserva guardada (id: $id)')));
                }).catchError((e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error (al guardar): ${e.toString()}')));
                });
              } catch (e) {
                // Synchronous validation error from provider
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando reserva: ${e.toString()}')));
                if (mounted) setState(()=> _isSaving = false);
                return;
              }

              if (!mounted) return;
              // Immediately navigate back one level (avoid heavy rebuilds)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserva en proceso')));
              // Pop the reservation flow; return to previous screen (product detail or list)
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando reserva: ${e.toString()}')));
            } finally {
              if (mounted) setState(()=> _isSaving = false);
            }
          }, child: _isSaving ? SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : Text(_page < 2 ? 'Siguiente' : 'Confirmar'), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal:24, vertical:14)))
        ]))
      ])
    );
  }

  double _computeTotal(product, int qty){
    final price = product?.price ?? 0.0;
    int nights = 1;
    if (_startDate != null && _endDate != null) {
      nights = _endDate!.difference(_startDate!).inDays;
      if (nights <= 0) nights = 1;
    }
    return price * qty * nights;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    // Compute unavailable dates for the selected product (if any)
    final reservationsProv = Provider.of<ReservationsProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String,dynamic>?;
    final productId = args?['id'] as String?;
    final products = Provider.of<ProductsProvider>(context, listen: false);
    final product = productId != null ? products.findById(productId) : null;

    // Build a set of blocked dates (only the date component)
    final Set<DateTime> blocked = {};
    if (product != null) {
      final svc = product.name.toLowerCase();
      for (final r in reservationsProv.reservations) {
        try {
          final rsvc = (r['service'] ?? '').toString().toLowerCase();
          final rdateStr = (r['date'] ?? '').toString();
          if (rsvc != svc) continue;
          // ignore cancelled or completed reservations for blocking
          final status = (r['status'] ?? '').toString().toLowerCase();
          if (status == 'cancelada' || status == 'cancelado' || status == 'completada' || status == 'completed') continue;
          final d = DateTime.tryParse(rdateStr);
          if (d == null) continue;
          blocked.add(DateTime(d.year, d.month, d.day));
        } catch (_) {
          // ignore malformed entries
        }
      }
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );

    if (picked != null) {
      // Validate that the picked range does not include any blocked date
      bool intersectsBlocked = false;
      for (var d = picked.start; !d.isAfter(picked.end); d = d.add(Duration(days: 1))) {
        final dayOnly = DateTime(d.year, d.month, d.day);
        if (blocked.contains(dayOnly)) { intersectsBlocked = true; break; }
      }
      if (intersectsBlocked) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('El rango seleccionado incluye días ya reservados. Elija otras fechas.')));
        return;
      }
      setState((){ _startDate = picked.start; _endDate = picked.end; });
    }
  }

  Future<void> _pickGuests(BuildContext context) async {
    final result = await showDialog<int>(context: context, builder: (ctx){
      int tmp = _guests;
      return AlertDialog(title: Text('Seleccionar huéspedes'), content: StatefulBuilder(builder: (ctx, setState){
        return Row(children:[IconButton(onPressed: ()=> setState(()=> tmp = tmp>1? tmp-1:1), icon: Icon(Icons.remove)), Text('$tmp'), IconButton(onPressed: ()=> setState(()=> tmp++), icon: Icon(Icons.add))]);
      }), actions: [TextButton(onPressed: ()=> Navigator.of(ctx).pop(null), child: Text('Cancelar')), TextButton(onPressed: ()=> Navigator.of(ctx).pop(tmp), child: Text('Aceptar'))]);
    });
    if (result != null) setState(()=> _guests = result);
  }

  void _showPriceDetails(BuildContext context, product, int qty){
    final nights = (_startDate != null && _endDate != null) ? _endDate!.difference(_startDate!).inDays : 1;
    showModalBottomSheet(context: context, builder: (ctx){
      return Padding(padding: EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Detalles de precio', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height:8),
        Text('Precio por noche: COP ${ (product?.price ?? 0).toStringAsFixed(0)}'),
        Text('Noches: $nights'),
        Text('Cantidad: $qty'),
        SizedBox(height:8), Text('Total: COP ${_computeTotal(product, qty).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height:12), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: ()=> Navigator.of(ctx).pop(), child: Text('Cerrar')))
      ]));
    });
  }

  Future<void> _showAddCard(BuildContext context) async {
    // Use a dialog instead of a bottom sheet to reduce layout/keyboard issues
    final numberCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text('Agrega los datos de la tarjeta'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: numberCtrl, decoration: InputDecoration(labelText: 'Número de tarjeta'), keyboardType: TextInputType.number),
          Row(children:[Expanded(child: TextField(controller: expCtrl, decoration: InputDecoration(labelText: 'Caducidad'))), SizedBox(width:8), Expanded(child: TextField(controller: cvvCtrl, decoration: InputDecoration(labelText: 'Código CVV'), obscureText: true))]),
          TextField(controller: zipCtrl, decoration: InputDecoration(labelText: 'Código postal')),
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.of(ctx).pop(), child: Text('Cancelar')),
          ElevatedButton(onPressed: (){
            // In a real app you'd validate and send the card data to a payment gateway.
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarjeta agregada (simulado)')));
          }, child: Text('Listo'))
        ],
      );
    });
  }
}
