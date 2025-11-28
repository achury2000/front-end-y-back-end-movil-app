import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/roles_provider.dart';

class RoleFormScreen extends StatefulWidget {
  static const routeNameCreate = '/roles/create';
  static const routeNameEdit = '/roles/edit';

  @override
  _RoleFormScreenState createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _id;
  String _name = '';
  String _description = '';
  bool _active = true;
  bool _loading = false;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(_id == null){
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) _id = args;
      if (_id != null){
        final prov = Provider.of<RolesProvider>(context, listen: false);
        final role = prov.roles.firstWhere((r) => r['id'] == _id, orElse: () => {});
        if (role.isNotEmpty){
          _name = role['name'] ?? '';
          _description = role['description'] ?? '';
          _active = role['active'] ?? true;
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(()=> _loading = true);
    final prov = Provider.of<RolesProvider>(context, listen: false);
    final data = {'name': _name, 'description': _description, 'active': _active};
    if (_id == null){
      await prov.addRole(data);
    } else {
      await prov.updateRole(_id!, data);
    }
    setState(()=> _loading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_id == null ? 'Crear Rol' : 'Editar Rol')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children:[
            TextFormField(initialValue: _name, decoration: InputDecoration(labelText: 'Nombre'), validator: (v)=> v==null||v.isEmpty? 'Nombre requerido': null, onSaved: (v)=> _name = v ?? ''),
            SizedBox(height:12),
            TextFormField(initialValue: _description, decoration: InputDecoration(labelText: 'Descripción'), maxLines:3, onSaved: (v)=> _description = v ?? ''),
            SizedBox(height:12),
            SwitchListTile(title: Text('Activo'), value: _active, onChanged: (v)=> setState(()=> _active = v)),
            SizedBox(height:20),
            _loading ? CircularProgressIndicator() : Row(children:[Expanded(child: ElevatedButton(onPressed: _save, child: Text('Guardar')))])
          ]),
        )
      ),
    );
  }
}
