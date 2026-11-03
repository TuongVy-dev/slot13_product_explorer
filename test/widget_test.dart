import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:slot13_product_explorer/main.dart';
import 'package:slot13_product_explorer/models/product.dart';

Map<String, dynamic> productJson(int id) => {
      'id': id,
      'title': 'Product $id',
      'description': 'Description of $id',
      'image': 'https://example.com/$id.png',
      'price': 10 * id,
    };

void main() {
  test('Product.fromJson parses int price as double', () {
    final p = Product.fromJson(productJson(1));
    expect(p.price, 10.0);
    expect(p.id, 1);
  });

  testWidgets('Loading → Error + Retry → List → Detail by ID', (tester) async {
    var serverDown = true;
    final requests = <String>[];
    final client = MockClient((req) async {
      requests.add(req.url.path);
      if (serverDown) return http.Response('error', 500);
      if (req.url.path == '/products') {
        return http.Response(jsonEncode([productJson(1), productJson(2)]), 200);
      }
      final id = int.parse(req.url.pathSegments.last);
      return http.Response(jsonEncode(productJson(id)), 200);
    });
    // Mọi lời gọi http.get bên trong callback sẽ dùng MockClient
    Future<void> withApi(Future<void> Function() body) =>
        http.runWithClient(body, () => client);

    await withApi(() => tester.pumpWidget(const ProductExplorerApp()));
    expect(find.text('Loading products...'), findsOneWidget);

    await withApi(() => tester.pump());
    expect(find.text('Retry'), findsOneWidget);

    serverDown = false;
    await withApi(() async {
      await tester.tap(find.text('Retry'));
      await tester.pump(); // Loading
      await tester.pump(); // Data
    });
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);

    await withApi(() async {
      await tester.tap(find.text('Product 2'));
      await tester.pumpAndSettle();
    });
    expect(find.text('Description of 2'), findsOneWidget);
    expect(requests.last, '/products/2');

    // Rebuild không gọi lại API (Future đã được cache trong initState)
    final count = requests.length;
    await withApi(() => tester.pump());
    expect(requests.length, count);
  });
}
