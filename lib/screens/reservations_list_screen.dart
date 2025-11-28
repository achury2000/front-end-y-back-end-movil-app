// parte isa
// parte linsaith
// parte juanjo
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
// import '../data/mock_reservations.dart';
import '../providers/reservations_provider.dart';
import '../widgets/admin_only.dart';
import '../providers/clients_provider.dart';
import '../providers/auth_provider.dart';

class ReservationsListScreen extends StatefulWidget {
  static const routeName = '/reservations';
  @override
  _ReservationsListScreenState createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  String _filter = 'Activas';
  String _search = '';
  Timer? _debounce;

  @override
  void dispose(){
    try{ _debounce?.cancel(); } catch(_){}
    super.dispose();
  }
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ReservationsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    List<Map<String,dynamic>> filtered = prov.search(query: _search, status: _filter=='Todas'? null : _filter);
    return Scaffold(
      appBar: AppBar(title: Text('Reservas'), actions:[
        if (auth.hasAnyRole(['admin'])) IconButton(icon: Icon(Icons.download), onPressed: (){
          final csv = prov.exportCsv();
          showDialog(context: context, builder: (_){ return AlertDialog(title: Text('CSV de reservas'), content: SingleChildScrollView(child: SelectableText(csv)), actions: [TextButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('Cerrar'))]); });
        }),
        if (auth.hasAnyRole(['admin'])) IconButton(icon: Icon(Icons.upload_file), onPressed: () async {
          final ctrl = TextEditingController();
          final res = await showDialog<bool>(context: context, builder: (_){
            return AlertDialog(
              title: Text('Importar CSV de reservas'),
              content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children:[
                Text('Pega el CSV abajo (encabezados deben coincidir)'),
                SizedBox(height:8),
                TextField(controller: ctrl, maxLines:8, decoration: InputDecoration(border: OutlineInputBorder()))
              ])),
              actions: [
                TextButton(onPressed: ()=> Navigator.of(context).pop(false), child: Text('Cancelar')),
                TextButton(onPressed: ()=> Navigator.of(context).pop(true), child: Text('Importar'))
              ]
            );
          });
          if (res == true) {
            final csv = ctrl.text.trim();
            if (csv.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV vacío')));
              return;
            }
            try {
              final actor = {'id': auth.user?.id ?? '', 'name': auth.user?.name ?? ''};
              await prov.importFromCsv(csv, replace: false, actor: actor);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Importado correctamente')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar CSV')));
            }
          }
        })
      ]),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children:[
          Row(children:[
            Expanded(child: DropdownButtonFormField<String>(initialValue: _filter, items: ['Activas','Completadas','Canceladas','Todas'].map((s)=> DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v)=> setState(()=> _filter = v ?? 'Activas'), decoration: InputDecoration(labelText: 'Filtrar por estado'))),
              SizedBox(width:12),
              AdminOnly(child: ElevatedButton(onPressed: ()=> Navigator.of(context).pushNamed('/reservations/create'), child: Text('Crear')))
          ]),
            SizedBox(height:8),
            // Search field (debounced). Do not search empty input.
            TextField(
              decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por ID, servicio, fecha, estado...'),
              onChanged: (v){
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(Duration(milliseconds: 400), (){
                  setState(()=> _search = v.trim());
                });
              },
              onSubmitted: (v){ if (v.trim().isEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingrese un criterio de búsqueda'))); },
            ),
          SizedBox(height:12),
          Expanded(child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_,__)=>SizedBox(height:8),
            itemBuilder: (ctx,i){
              final r = filtered[i];
              final clientName = Provider.of<ClientsProvider>(context).getById(r['clientId'] ?? '')?['name'];
              return Card(child: ListTile(
                title: Text('${r['service']}'),
                subtitle: Text('${r['date']} • ${r['status']}${clientName!=null? ' • $clientName' : ''}'),
                trailing: Icon(Icons.chevron_right),
                onTap: ()=> Navigator.of(context).pushNamed('/reservations/detail', arguments: r)
              ));
            }
          ))
        ])
      ),
    );
  }
}
