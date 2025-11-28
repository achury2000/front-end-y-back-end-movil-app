// parte lucho
// parte linsaith
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/roles_provider.dart';
import '../widgets/admin_only.dart';
import 'role_detail_screen.dart';
import '../providers/auth_provider.dart';

class RolesListScreen extends StatefulWidget {
  static const routeName = '/roles';
  @override
  _RolesListScreenState createState() => _RolesListScreenState();
}

class _RolesListScreenState extends State<RolesListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final rolesProv = Provider.of<RolesProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final all = rolesProv.roles;
    final filtered = all.where((r) => r['name'].toLowerCase().contains(_query.toLowerCase()) || r['description'].toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Roles'), actions: [AdminOnly(child: IconButton(icon: Icon(Icons.add), onPressed: ()=> Navigator.of(context).pushNamed('/roles/create')))]),
      floatingActionButton: AdminOnly(child: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: ()=> Navigator.of(context).pushNamed('/roles/create'),
      )),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _searchCtrl,
              decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre o descripción', border: OutlineInputBorder()),
              onChanged: (v){ setState(()=> _query = v); },
            ),
            SizedBox(height:12),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_,__)=>SizedBox(height:10),
                itemBuilder: (ctx,i){ final r = filtered[i];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                            Text(r['name'], style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height:6),
                            Text(r['description'], style: TextStyle(color: Colors.black54)),
                          ])),
                          Column(children:[
                            Chip(label: Text((r['active'] as bool) ? 'Activo' : 'Inactivo'), backgroundColor: (r['active'] as bool) ? Colors.green[50] : Colors.grey[200]),
                            Row(children:[
                              IconButton(icon: Icon(Icons.visibility), tooltip: 'Detalle', onPressed: ()=> Navigator.of(context).pushNamed(RoleDetailScreen.routeName, arguments: r['id'])),
                              IconButton(icon: Icon(Icons.edit), onPressed: ()=> Navigator.of(context).pushNamed('/roles/edit', arguments: r['id'])),
                              IconButton(icon: Icon(Icons.delete), onPressed: () async {
                                final confirm = await showDialog<bool>(context: context, builder: (ctx)=> AlertDialog(
                                  title: Text('Confirmar eliminación'),
                                  content: Text('¿Seguro que deseas eliminar el rol "${r['name']}"? Esta acción no se puede deshacer.'),
                                  actions: [TextButton(onPressed: ()=> Navigator.of(ctx).pop(false), child: Text('Cancelar')), TextButton(onPressed: ()=> Navigator.of(ctx).pop(true), child: Text('Eliminar'))],
                                ));
                                if (confirm == true) {
                                  await rolesProv.deleteRoleWithAudit(r['id'], actor: {'id': auth.user?.id ?? '', 'name': auth.user?.name ?? ''});
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rol eliminado')));
                                }
                              }),
                              IconButton(icon: Icon(Icons.security), onPressed: ()=> Navigator.of(context).pushNamed('/roles/assign', arguments: r['id'])),
                            ])
                          ])
                        ],
                      ),
                    ),
                  );
                }
              ),
            )
          ],
        ),
      ),
    );
  }
}
