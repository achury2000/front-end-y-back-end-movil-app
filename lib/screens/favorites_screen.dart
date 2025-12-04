import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fav = Provider.of<FavoritesProvider>(context);
    final products = Provider.of<ProductsProvider>(context);
    final items = products.items.where((p) => fav.isFavorite(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Favoritos')),
      body: items.isEmpty
          ? Center(child: Text('No tienes favoritos aún'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = items[i];
                return ListTile(
                  leading: p.imageUrl != '' ? Image.network(p.imageUrl, width: 56, height: 56, fit: BoxFit.cover) : null,
                  title: Text(p.name),
                  subtitle: Text('COP ${p.price.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: Icon(fav.isFavorite(p.id) ? Icons.favorite : Icons.favorite_border, color: fav.isFavorite(p.id) ? Colors.red : null),
                    onPressed: () => fav.toggle(p.id),
                  ),
                  onTap: () => Navigator.of(context).pushNamed(ProductDetailScreen.routeName, arguments: p.id),
                );
              },
            ),
    );
  }
}
