import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  String _authToken;
  String _userId;
  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  void update(authToken, userId, orders) {
    _authToken = authToken;
    _userId = userId;
    _orders = orders;
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        'https://shopping-6da64-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken';
    final timestamp = DateTime.now();
    final response = await http.post(
      Uri.parse(url),
      body: json.encode(
        {
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'products': cartProducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList()
        },
      ),
    );
    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: DateTime.now(),
        products: cartProducts,
      ),
    );
    notifyListeners();
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        'https://shopping-6da64-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken';

    final response = await http.get(Uri.parse(url));

    final List<OrderItem> _loadedOrder = [];

    final extratedOrder = json.decode(response.body) as Map<String, dynamic>;

    if (extratedOrder == null) {
      return;
    }

    extratedOrder.forEach((orderId, orderData) {
      _loadedOrder.add(OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map(
                (prod) => CartItem(
                  id: prod['id'],
                  title: prod['title'],
                  quantity: prod['quantity'],
                  price: prod['price'],
                ),
              )
              .toList()));
    });
    _orders = _loadedOrder;
    notifyListeners();
  }
}
