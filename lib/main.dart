import 'package:flutter/material.dart';
import 'screens/product_list_screen.dart';

void main() {
  runApp(const ProductExplorerApp());
}

class ProductExplorerApp extends StatelessWidget {
  const ProductExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Explorer',
      theme: ThemeData(useMaterial3: true),
      home: const ProductListScreen(),
    );
  }
}
