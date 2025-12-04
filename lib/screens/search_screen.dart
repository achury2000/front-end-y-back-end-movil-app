import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _category = 'Rutas';
  String _q = '';

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ProductsProvider>(context, listen: false);
      prov.loadInitial(category: _category);
    });
  }

  Widget build(BuildContext context) {
    final prov = Provider.of<ProductsProvider>(context);
    final list = prov.items.where((p) {
      if (p.category != _category) return false;
      if (_q.isEmpty) return true;
      return p.name.toLowerCase().contains(_q.toLowerCase()) || p.description.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Buscar', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) async {
                    setState(() => _q = v);
                    // reload filtered results
                    try{
                      await prov.loadInitial(category: _category, query: _q);
                    }catch(_){ }
                  },
                ),
              ),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: _category,
                items: ['Rutas', 'Fincas'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) async {
                  setState(() => _category = v ?? 'Rutas');
                  try{
                    await prov.loadInitial(category: _category, query: _q);
                  }catch(_){ }
                },
              )
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('No se encontraron resultados'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final p = list[i];
                      return ListTile(
                        leading: p.imageUrl != '' ? Image.network(p.imageUrl, width: 56, height: 56, fit: BoxFit.cover) : null,
                        title: Text(p.name),
                        subtitle: Text('COP ${p.price.toStringAsFixed(0)}'),
                        onTap: () => Navigator.of(context).pushNamed(ProductDetailScreen.routeName, arguments: p.id),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
