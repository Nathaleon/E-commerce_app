import 'package:flutter/material.dart';
import 'package:projectakhir_mobile/models/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl.isNotEmpty)
              Image.network(product.imageUrl)
            else
              const FlutterLogo(size: 100),
            const SizedBox(height: 16),
            Text("Harga: Rp${product.price}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Stok: ${product.stock}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Kategori: ${product.category}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Deskripsi:", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(product.description),
          ],
        ),
      ),
    );
  }
}
