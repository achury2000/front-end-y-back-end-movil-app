import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reviews_provider.dart';
import '../models/review.dart';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reviewsProv = Provider.of<ReviewsProvider>(context);
    final items = reviewsProv.items;

    return Scaffold(
      appBar: AppBar(title: Text('Mensajes')),
      body: items.isEmpty
          ? Center(child: Text('No hay mensajes'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (ctx, i) {
                final Review r = items[i];
                return ListTile(
                  title: Text(r.comment ?? '(sin comentario)'),
                  subtitle: Text('Autor: ${r.authorId} • Target: ${r.targetType}/${r.targetId}'),
                  onTap: () => Navigator.of(context).pushNamed('/reviews/detail', arguments: {'id': r.id}),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/reviews/create'),
        child: Icon(Icons.add_comment),
        tooltip: 'Crear Mensaje/Comentario',
      ),
    );
  }
}
