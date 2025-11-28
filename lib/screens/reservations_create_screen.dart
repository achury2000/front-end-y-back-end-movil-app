// parte isa
// parte linsaith
// parte juanjo
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/services_provider.dart';
import '../providers/fincas_provider.dart';
import 'package:flutter/services.dart';

/// Pantalla/Formulario para crear una reserva.
///
/// Responsabilidades:
/// - Recolectar datos (finca, servicio, cliente, fecha/hora, número de personas y notas) y validar disponibilidad.
/// - Al confirmar, crea la reserva via `ReservationsProvider.addReservation` y muestra confirmación/copiado.
///
/// Herencia / Overrides:
/// - `StatefulWidget` con lógica en `_ReservationsCreateScreenState`, usa pickers de fecha y hora y valida solapamientos.
class ReservationsCreateScreen extends StatefulWidget {
  static const routeName = '/reservations/create';
  @override
  _ReservationsCreateScreenState createState() => _ReservationsCreateScreenState();
}

class _ReservationsCreateScreenState extends State<ReservationsCreateScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  int _people = 2;
  final _notesCtrl = TextEditingController();
  String? _selectedClientId;
  String? _selectedServiceId;
  String? _fincaId;

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)));
    if (d != null) setState(()=> _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 9, minute: 0));
    if (t != null) setState(()=> _time = t);
  }

  void _confirm(){
    final prov = Provider.of<ReservationsProvider>(context, listen: false);
    final servicesProv = Provider.of<ServicesProvider>(context, listen: false);

    final dateStr = _date?.toLocal().toString().split(' ')[0] ?? DateTime.now().toLocal().toString().split(' ')[0];
    final timeStr = _time != null ? '${_time!.hour.toString().padLeft(2,'0')}:${_time!.minute.toString().padLeft(2,'0')}' : '';

    final data = {
      'service': _selectedServiceId ?? 'Servicio seleccionado',
      'serviceId': _selectedServiceId,
      'date': dateStr,
      'time': timeStr,
      'people': _people,
      'notes': _notesCtrl.text,
      if (_selectedClientId != null && _selectedClientId!.isNotEmpty) 'clientId': _selectedClientId,
      'status': 'Activa'
    };

    // Validate capacity and overlaps by time (if a service selected)
    if (_selectedServiceId != null) {
      final svc = servicesProv.getById(_selectedServiceId!);
      if (svc != null) {
        final duration = svc.durationMinutes;

        DateTime? newStart;
        DateTime? newEnd;
        try {
          if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
            final parts = timeStr.split(':');
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            newStart = DateTime.parse(dateStr).add(Duration(hours: hour, minutes: minute));
            newEnd = newStart.add(Duration(minutes: duration));
          }
        } catch (_) { newStart = null; newEnd = null; }

        final parsedDate = (dateStr.isNotEmpty) ? DateTime.tryParse(dateStr) : null;
        final from = parsedDate != null ? DateTime(parsedDate.year, parsedDate.month, parsedDate.day) : null;
        final to = parsedDate != null ? DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 23, 59, 59) : null;
        final existing = prov.search(service: _selectedServiceId, from: from, to: to);
        var overlapping = 0;
        for (final r in existing) {
          try {
            final t = (r['time'] ?? '').toString();
            final parts = t.split(':');
            if (parts.length < 2) continue;
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final exStart = DateTime.parse(r['date']).add(Duration(hours: h, minutes: m));
            final exEnd = exStart.add(Duration(minutes: duration));
            if (newStart != null && newEnd != null) {
              final overlap = newStart.isBefore(exEnd) && exStart.isBefore(newEnd);
              if (overlap) overlapping++;
            }
          } catch (_) { continue; }
        }

        final cap = svc.capacity;
        if (cap > 0 && overlapping >= cap) {
          showDialog(context: context, builder: (_) => AlertDialog(title: Text('Sin cupos'), content: Text('No hay cupos disponibles para el servicio en la franja horaria seleccionada.'), actions: [TextButton(onPressed: ()=>Navigator.of(context).pop(), child: Text('OK'))]));
          return;
        }
      }
    }

    prov.addReservation(data).then((resNumber){
      showDialog(context: context, builder: (_)=> AlertDialog(
        title: Text('Reserva Confirmada'),
        content: Text('Número de reserva: $resNumber'),
        actions: [
          TextButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('OK')),
          TextButton(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: resNumber));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Número copiado')));
          }, child: Text('Copiar')),
          TextButton(onPressed: (){
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/reservations/detail', arguments: resNumber);
          }, child: Text('Ver detalle'))
        ]
      ));
    }).catchError((e){
      final msg = e.toString().replaceFirst('Exception: ', '');
      showDialog(context: context, builder: (_)=> AlertDialog(title: Text('Error'), content: Text(msg), actions: [TextButton(onPressed: ()=> Navigator.of(context).pop(), child: Text('OK'))]));
    });
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && (_fincaId == null || _fincaId != arg)) {
      _fincaId = arg;
    }
    return Scaffold(
      appBar: AppBar(title: Text('Crear Reserva')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(children:[
            if (_fincaId != null) Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Finca seleccionada', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height:8),
            Consumer<FincasProvider>(builder: (ctx, fp, _) {
              final f = fp.findById(_fincaId!);
              if (f == null) return Text('Finca no encontrada');
              return Text('${f.name} • ${f.location}');
            }),
          ]))),
          Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Servicio', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height:8),
              Builder(builder: (ctx) {
              final sp = Provider.of<ServicesProvider>(ctx);
              final fp = Provider.of<FincasProvider>(ctx);
              List services;
              if (_fincaId != null) {
                try {
                  final f = fp.findById(_fincaId!);
                  if (f != null) {
                    services = f.serviceIds.map((id) => sp.getById(id)).where((s) => s!=null).map((s) => s!).toList();
                  } else {
                    services = sp.search();
                  }
                } catch(_) { services = sp.search(); }
              } else services = sp.search();
              final items = services.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList();
              return DropdownButtonFormField<String>(initialValue: _selectedServiceId, items: [DropdownMenuItem(value: '', child: Text('Seleccionar servicio')), ...items], onChanged: (v)=> setState(()=> _selectedServiceId = (v!=null && v.isNotEmpty)? v : null));
            })
          ]))),
          Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Cliente (opcional)', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height:8),
            Builder(builder: (ctx){
                final prov = Provider.of<ClientsProvider>(ctx);
                if (prov.loading) return SizedBox(height:48, child: Center(child: CircularProgressIndicator()));
                final items = prov.clients.map((c)=> DropdownMenuItem<String>(value: c['id'] as String, child: Text('${c['name']} (${c['email'] ?? ''})'))).toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedClientId,
                  items: [DropdownMenuItem<String>(value: '', child: Text('Cliente no asignado')),...items],
                  onChanged: (v)=> setState(()=> _selectedClientId = (v!=null && v.isNotEmpty)? v : null),
                  decoration: InputDecoration(),
                );
            })
          ]))),
          Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Selecciona fecha y hora', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height:8),
            Row(children:[
              Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: Icon(Icons.calendar_today), label: Text(_date==null? 'Elegir fecha' : _date!.toLocal().toString().split(' ')[0]))),
              SizedBox(width:12),
              Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: Icon(Icons.access_time), label: Text(_time==null? 'Elegir hora' : _time!.format(context)))),
            ]),
            SizedBox(height:12),
            Text('Número de personas', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height:6),
            DropdownButton<int>(value: _people, items: [1,2,3,4,5,6,8,10].map((n)=> DropdownMenuItem(value:n, child: Text('$n'))).toList(), onChanged: (v)=> setState(()=> _people = v ?? 2)),
            SizedBox(height:12),
            TextFormField(controller: _notesCtrl, maxLines:3, decoration: InputDecoration(labelText: 'Notas / Requerimientos')),
            SizedBox(height:12),
            // Marcador de disponibilidad
            Row(children:[Icon(Icons.check_circle, color: Colors.green), SizedBox(width:8), Expanded(child: Text('Disponibilidad: Disponible (actualizado en tiempo real)'))]),
            SizedBox(height:14),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _confirm, child: Text('Confirmar')))
          ])))
        ])
      ),
    );
  }
}
