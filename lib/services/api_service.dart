import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_line.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // For Android Emulator

  // Get all menu items - with 1 second timeout
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/menu'))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => MenuItem(
                id: item['id'],
                name: item['name'],
                price: item['price'].toDouble(),
                category: item['category'],
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  // Get categories - with 1 second timeout
  static Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories'))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  // Add menu item
  static Future<void> addMenuItem(MenuItem item) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/menu'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'category': item.category,
        }),
      );
    } catch (e) {
      print('API Error: $e');
    }
  }

  // Save order
  static Future<void> saveOrder(Order order) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': order.id,
          'items': order.items
              .map(
                (line) => {
                  'itemId': line.itemId,
                  'name': line.name,
                  'price': line.price,
                  'quantity': line.quantity,
                  'total': line.total,
                },
              )
              .toList(),
          'subtotal': order.subtotal,
          'taxPercent': order.taxPercent,
          'taxAmount': order.taxAmount,
          'discount': order.discount,
          'total': order.total,
        }),
      );
    } catch (e) {
      print('API Error: $e');
    }
  }

  // Get all orders
  static Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (order) => Order(
                id: order['orderId'],
                items: (order['items'] as List)
                    .map(
                      (line) => OrderLine(
                        itemId: line['itemId'],
                        name: line['name'],
                        price: line['price'].toDouble(),
                        quantity: line['quantity'],
                        total: line['total'].toDouble(),
                      ),
                    )
                    .toList(),
                subtotal: order['subtotal'].toDouble(),
                taxPercent: order['taxPercent'].toDouble(),
                taxAmount: order['taxAmount'].toDouble(),
                discount: order['discount'].toDouble(),
                total: order['total'].toDouble(),
                createdAt: DateTime.parse(order['createdAt']),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }
}
