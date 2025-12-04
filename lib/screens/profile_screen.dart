import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/user.dart';
import 'account_settings_screen.dart';
import 'help_screen.dart';
import 'view_profile_screen.dart';
import 'privacy_screen.dart';
import 'recommend_host_screen.dart';
import 'find_cohost_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState(){
    super.initState();
    // Defer loading the profile until after the first frame to avoid
    // calling notifyListeners()/setState during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile('u3');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final user = profile.user;
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: profile.loading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top card with avatar
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(radius: 30, child: Text((user?.name ?? 'U').substring(0,1), style: TextStyle(fontSize:24))),
                SizedBox(width:12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text(user?.name ?? '', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold)),
                  SizedBox(height:4),
                  Text(user?.role ?? 'Huésped', style: TextStyle(color: Colors.grey[700]))
                ])),
                Row(children: [
                  IconButton(onPressed: ()=>Navigator.of(context).pushNamed(AccountSettingsScreen.routeName), icon: Icon(Icons.settings)),
                  IconButton(onPressed: ()=>_showEditDialog(context, profile), icon: Icon(Icons.edit))
                ])
              ])
            ),
          ),
          SizedBox(height:12),

          // Two small cards
          Row(children:[
            Expanded(child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation:2,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed('/trips_history'),
                child: Padding(padding: EdgeInsets.all(12), child: Column(children:[
                  Icon(Icons.card_travel, size:40, color: Theme.of(context).primaryColor),
                  SizedBox(height:8),
                  Text('Viajes anteriores')
                ])),
              ),
            )),
            SizedBox(width:10),
            Expanded(child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation:2,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed('/connections'),
                child: Padding(padding: EdgeInsets.all(12), child: Column(children:[
                  Icon(Icons.group, size:40, color: Theme.of(context).primaryColor),
                  SizedBox(height:8),
                  Text('Conexiones')
                ])),
              ),
            )),
          ]),

          SizedBox(height:12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation:3,
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: Icon(Icons.emoji_people, size:40, color: Theme.of(context).primaryColor),
              title: Text('Conviértete en anfitrión', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Empieza a anfitrionar y genera ingresos adicionales, ¡es muy sencillo!'),
              onTap: () => Navigator.of(context).pushNamed(RecommendHostScreen.routeName),
            ),
          ),

          SizedBox(height:8),
          // Options list
          Card(child: Column(children:[
            ListTile(leading: Icon(Icons.settings_outlined), title: Text('Configuración de la cuenta'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(AccountSettingsScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.help_outline), title: Text('Obtén ayuda'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(HelpScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.person_outline), title: Text('Ver perfil'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(ViewProfileScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacidad'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(PrivacyScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.group_add_outlined), title: Text('Recomienda a un anfitrión'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(RecommendHostScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.search_outlined), title: Text('Encuentra un coanfitrión'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(FindCohostScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.book_outlined), title: Text('Legal'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed(LegalScreen.routeName)),
            Divider(height:1),
            ListTile(leading: Icon(Icons.exit_to_app), title: Text('Cierra la sesión'), trailing: Icon(Icons.chevron_right), onTap: ()=>Navigator.of(context).pushNamed('/logout')),
          ])),
        ]),
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, ProfileProvider profile) {
    final user = profile.user;
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final addressCtrl = TextEditingController(text: user?.address ?? '');

    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Editar perfil'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nombre'), validator: (v)=> (v==null||v.trim().isEmpty)?'Nombre requerido':null),
          TextFormField(
            controller: phoneCtrl,
            decoration: InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
            validator: (v){
              if(v==null||v.trim().isEmpty) return null;
              final text = v.trim();
              if(text.length < 7 || text.length > 15) return 'Teléfono inválido';
              final digitsOnly = text.split('').every((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57);
              if(!digitsOnly) return 'Teléfono inválido';
              return null;
            }
          ),
          TextFormField(controller: addressCtrl, decoration: InputDecoration(labelText: 'Dirección')),
        ]),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.of(ctx).pop(), child: Text('Cancelar')),
        ElevatedButton(onPressed: () async {
          if(!_formKey.currentState!.validate()) return;
          final u = profile.user!;
          final updated = User(id: u.id, name: nameCtrl.text.trim(), email: u.email, role: u.role, phone: phoneCtrl.text.trim(), address: addressCtrl.text.trim());
          await profile.updateProfile(updated);
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Perfil actualizado')));
        }, child: profile.loading ? SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : Text('Guardar'))
      ],
    ));
  }
}
